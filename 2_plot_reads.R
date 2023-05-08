plot_counts = function(input_df = NA, n_breaks = 10, read_width_adjust_P1467_chr6 = FALSE){
    for(mycell in unique(input_df$cell)){
        print(mycell)
        
        plotinput = input_df %>% 
            arrange(strand, POS) %>% 
            filter(cell == mycell) %>% 
            distinct() %>% 
            mutate(mateL_start = ifelse(strand=="C",POS,(POS+readlen+insert)), 
                   mateL_end = mateL_start+readlen, 
                   mateR_start = ifelse(strand=="W",POS,(mateL_start+insert-readlen)),
                   mateR_end = mateR_start+readlen, # old way
                   insert_line_start =  ifelse((mateL_end < mateR_start), mateL_end, NA),
                   insert_line_end =  ifelse((mateL_end < mateR_start), mateR_start, NA)) 
        
        plotmin = floor(min(plotinput$mateL_start) / 1000000)
        plotmax = ceiling(max(plotinput$mateR_end) / 1000000)
        plotsize = plotmax - plotmin
        plot_breaks = (plotmax - plotmin) / n_breaks
        mychrom = unique(plotinput$CHROM)
        
        plotinput = plotinput %>% 
            mutate(mateR_end = mateL_start + (mateL_start*(0.003 / plotsize)))
            
        if(read_width_adjust_P1467_chr6){
        adjust_constant = 0.00003 # value for this specific plot
        }else{
            adjust_constant = 0.003 # O.G. value
        }
    
        plotinput = plotinput %>%
            mutate(mateR_end = mateL_start + (mateL_start*(adjust_constant / plotsize)))
            
        # recalculate with new ends
        plotmin = floor(min(plotinput$mateL_start) / 1000000)
        plotmax = ceiling(max(plotinput$mateR_end) / 1000000)
        
        # loop to define y coordinate so that reads are not overlapping but as compact as possible
        plotinput$y = 1:nrow(plotinput)
        print("running loop to determine coordinates for read plotting...")
        for(i in 1:nrow(plotinput)){
            #print(paste(i,"out of",nrow(plotinput)))
            pot_lower_levels = plotinput$y[i] - 1
            current_start = plotinput$mateL_start[i]
            current_end = plotinput$mateR_end[i]
            if(pot_lower_levels > 0){
                completed = F
                for(j in 1:pot_lower_levels){
                    if(! completed){
                        tmp_lower_level_df = filter(plotinput, y == j)
                        if(nrow(tmp_lower_level_df) > 0){
                            for(p in 1:nrow(tmp_lower_level_df)){
                                tmp_lower_level_start = tmp_lower_level_df$mateL_start[p]
                                tmp_lower_level_end = tmp_lower_level_df$mateR_end[p]
                                if(!current_start %in% tmp_lower_level_start:tmp_lower_level_end & 
                                   !current_end %in% tmp_lower_level_start:tmp_lower_level_end){
                                    if(p == nrow(tmp_lower_level_df)){
                                        plotinput$y[i] = tmp_lower_level_df$y[p] 
                                        completed = T
                                        break
                                    }
                                }
                            }
                        }else{
                            plotinput$y[i] = j
                        }
                        if(j == pot_lower_levels & !completed) plotinput$y[i] = max(plotinput$y[1:(i-1)]) + 1
                    }
                }
            }
        }
        
        myplot = plotinput %>% 
            mutate(xmin = mateL_start / 1000000,
                   xmax = mateR_end / 1000000,
                   y = ifelse(strand=="C",-(y-.5),(y-.5)), 
                   strand = factor(strand, levels = c("W","C")),
                   insert_line_start = ifelse((insert_line_end - insert_line_start)< 55,NA, insert_line_start),
                   insert_line_end = ifelse((insert_line_end - insert_line_start)< 55,NA ,insert_line_end)) %>% 
            ggplot() + 
            geom_rect(aes(xmin = xmin,
                          xmax = xmax,# + (mateL_start*0.001), # old way
                          ymin=y-.4,ymax=y+.4, fill = strand),
                      linewidth = 100) +
            scale_fill_manual(values = c("sandybrown","paleturquoise4"), breaks =  c("W","C")) + 
            theme_bw() + 
            labs(title = paste0(mycell," ",mychrom),
                 y = "", x= "POS (Mb)", fill = "Strand") + 
            scale_x_continuous(breaks = seq(plotmin,plotmax,plot_breaks)) +
            theme(panel.grid.minor.y = element_blank(), panel.grid.major.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank())
        print(myplot)
    }
}

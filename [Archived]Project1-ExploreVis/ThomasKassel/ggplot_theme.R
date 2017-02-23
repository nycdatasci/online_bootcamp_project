#custom ggplot theme for consistency of graphics
library(ggplot2)
library(grid)

light_theme <- function(base_size=12,text_color='gray15'){
    theme(
      plot.title = element_text(size=rel(1.2),vjust=2,hjust=0.5,colour=text_color),
      plot.margin = unit(c(1.2,1.2,1.2,1.2),"lines"),
      axis.ticks = element_line(size=0.15),
      axis.text = element_text(colour=text_color,size=rel(0.8)),
      axis.title.x = element_text(vjust=-0.8,size=base_size,colour=text_color),
      axis.title.y = element_text(vjust=1.3,size=base_size,colour=text_color),
      panel.grid.major = element_line(size=0.15,colour='grey85'),
      panel.grid.minor = element_line(size=0.05,colour='grey85'),
      panel.background = element_rect(fill='white'),
      panel.border = element_rect(colour = "grey60", fill=NA, size=0.2),
      strip.background = element_rect(fill='grey80',colour="grey60",size=0.3),
      strip.text = element_text(colour=text_color,size=base_size)
    )
}


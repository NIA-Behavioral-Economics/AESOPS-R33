
#, repo = "http://cran.rstudio.com/")
library(cowplot)
library(haven)
library(sqldf)
library(ggplot2)
library(dplyr)
library(tidyr)
library(openxlsx)
library(ggtext)

#trimmed 
est_AB <- read_dta("/directory/est_AB.dta")
est_C <- read_dta("/directory/est_C.dta")

#predicted i.e. "adjusted" MME 
#convert to long format 
convert <- function(dat, nm) {
dat %>%
  select(
    prov_deid,
    assignment,
    week,
    avg_total_mme,
    mme_int_adj,
    mme_post_adj
  ) %>%
  pivot_longer(
    cols = c(avg_total_mme, mme_int_adj, mme_post_adj),
    names_to = "post",
    values_to = "MME"
  ) %>%
  filter(MME != 0) %>%
  mutate(bpa_group = nm) 
}

long_AB <- convert(est_AB, "AB")
long_C <- convert(est_C, "C")

#append 
total <- rbind(long_AB, long_C)
clinician <- sqldf("select prov_deid, assignment, post, bpa_group, avg(MME) as avg_mme, sum(MME) as sum_mme from total group by prov_deid, assignment, post, bpa_group order by prov_deid, bpa_group, post")
#write.xlsx(clinician, "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/R_AND_R/Data/boxplot_uncensored_adj.xlsx")

#function for boxplot 
theme_USGS_box <- function(base_family = "", ...){
  theme_bw(base_family = base_family, ...) +
    theme(panel.spacing.x = unit(-0.2, "lines"), panel.grid = element_blank(), plot.caption.position = "plot", 
          plot.caption = element_markdown(hjust = 0, halign = 0, size = 9, margin = margin(t = 15)),
          plot.margin = margin(t = 16, r = 5, b = 16, l = 5), axis.ticks.length = unit(-0.05, "in"),
          axis.ticks.x = element_blank(), panel.border = element_blank(), axis.line = element_line(color = "black"),
          strip.background = element_blank(), legend.position = ("bottom"),
          legend.margin = margin(t = -5), legend.box.margin = margin(t = -5), legend.spacing.y = unit(0, "pt"),
          aspect.ratio = 1, legend.background = element_blank())
}

update_geom_defaults("text",
                     list(size = 5,
                          family = ""))

#function to add boxplot legend 
#retrieved from: https://waterdata.usgs.gov/blog/boxplots/
ggplot_box_legend <- function(family = ""){
  
  # Create data to use in the boxplot legend:
  set.seed(100)
  
  sample_df <- data.frame(parameter = "test",
                          values = sample(500))
  
  # Extend the top whisker a bit:
  sample_df$values[1:100] <- 701:800
  # Make sure there's only 1 lower outlier:
  sample_df$values[1] <- -350
  
  # Function to calculate important values:
  ggplot2_boxplot <- function(x){
    
    quartiles <- as.numeric(quantile(x,
                                     probs = c(0.25, 0.5, 0.75)))
    
    names(quartiles) <- c("25th percentile",
                          "50th percentile\n(median)",
                          "75th percentile")
    
    IQR <- diff(quartiles[c(1,3)])
    
    upper_whisker <- max(x[x < (quartiles[3] + 1.5 * IQR)])
    lower_whisker <- min(x[x > (quartiles[1] - 1.5 * IQR)])
    
    upper_dots <- x[x > (quartiles[3] + 1.5*IQR)]
    lower_dots <- x[x < (quartiles[1] - 1.5*IQR)]
    
    return(list("quartiles" = quartiles,
                "25th percentile" = as.numeric(quartiles[1]),
                "50th percentile\n(median)" = as.numeric(quartiles[2]),
                "75th percentile" = as.numeric(quartiles[3]),
                "IQR" = IQR,
                "upper_whisker" = upper_whisker,
                "lower_whisker" = lower_whisker,
                "upper_dots" = upper_dots,
                "lower_dots" = lower_dots))
  }
  
  # Get those values:
  ggplot_output <- ggplot2_boxplot(sample_df$values)
  ggplot_output
  
  # Lots of text in the legend, make it smaller and consistent font:
  update_geom_defaults("text",
                       list(size = 3,
                            hjust = 0,
                            family = family))
  # Labels don't inherit text:
  update_geom_defaults("label",
                       list(size = 3,
                            hjust = 0,
                            family = family))
  
  
  # Create the legend:
  # The main elements of the plot (the boxplot, error bars, and count)
  # are the easy part.
  # The text describing each of those takes a lot of fiddling to
  # get the location and style just right:
  explain_plot <- ggplot() +
    stat_boxplot(data = sample_df,
                 aes(x = parameter, y=values),
                 geom ='errorbar', width = 0) +
    geom_boxplot(data = sample_df,
                 aes(x = parameter, y=values),
                 width = 0.3, fill = "lightgrey") +
    geom_text(aes(x = 1, y = 950, label = "2064"), hjust = 0.12) +
    geom_text(aes(x = 1.17, y = 950,
                  label = "Number of values"), fontface = "bold", vjust = 0.4, hjust = -0.15) +
    theme_minimal(base_size = 5, base_family = family) +
    geom_segment(aes(x = 2.3, xend = 2.3,
                     y = ggplot_output[["25th percentile"]],
                     yend = ggplot_output[["75th percentile"]])) +
    geom_segment(aes(x = 1.2, xend = 2.3,
                     y = ggplot_output[["25th percentile"]],
                     yend = ggplot_output[["25th percentile"]])) +
    geom_segment(aes(x = 1.2, xend = 2.3,
                     y = ggplot_output[["75th percentile"]],
                     yend = ggplot_output[["75th percentile"]])) +
    geom_text(aes(x = 2.4, y = ggplot_output[["50th percentile\n(median)"]]),
              label = "Interquartile\nrange", fontface = "bold",
              vjust = 0.4) +
    geom_text(aes(x = c(1.17,1.17),
                  y = c(ggplot_output[["upper_whisker"]],
                        ggplot_output[["lower_whisker"]]),
                  label = c("Largest value within 1.5 times\ninterquartile range above\n75th percentile",
                            "Smallest value within 1.5 times\ninterquartile range below\n25th percentile")),
              fontface = "bold", vjust = 0.9) +
    geom_text(aes(x = c(1.17),
                  y =  ggplot_output[["lower_dots"]],
                  label = "Outside value"),
              vjust = 0.5, fontface = "bold") +
    geom_text(aes(x = c(1.17),
                  y =  ggplot_output[["lower_dots"]],
                  label = "Value is >1.5 times the interquartile\nrange"),
              vjust = 1.5) +
    geom_label(aes(x = 1.17, y = ggplot_output[["quartiles"]],
                   label = names(ggplot_output[["quartiles"]])),
               vjust = c(0.4,0.5,0.4),
               fill = "white", label.size = 0) +
    ylab("") + xlab("") +
    theme(axis.text = element_blank(),
          axis.ticks = element_blank(),
          panel.grid = element_blank(),
          aspect.ratio = 4/3,
          plot.title = element_text(hjust = 0.10, vjust = 6, size = 10)) +
    coord_cartesian(xlim = c(1.4,3.1), ylim = c(-600, 900)) +
    labs(title = "MME by Prescription Type")
  
  explain_plot <- explain_plot +
    theme(
      plot.margin = margin(t = 5, r = 5, b = 5, l = 70)
    )
  
  return(explain_plot)
  
}

#legend
legend_plot <- ggplot_box_legend()

graph <- function(dat, caption_text, outcome, number, datout) {
  dat <- dat %>% rename_with(tolower)
  dat$bpa_group <- as.factor(dat$bpa_group)
  dat$post <- as.factor(dat$post)
  
  #graph
  #boxplots <-
  p <- ggplot(data = dat, aes(x = as.factor(assignment), y = {{ outcome }}, fill = as.factor(post))) +
       geom_boxplot(aes(fill = as.factor(post)), position = position_dodge(width = 0.5), width=0.3) +
       facet_wrap(~ bpa_group, scales = "free_y",labeller = labeller(bpa_group = c( AB = "Naive and Recently Exposed",
       C = "Long-Term High-Dose"))) +
       labs(caption = caption_text) +
       scale_x_discrete(labels = c("0" = "Control", "1" = "Intervention")) +
       ylab("") +
       xlab("") +
       theme_USGS_box() +
       scale_fill_manual(name = "Study Period", labels = c("Pre-intervention", "Intervention", "Follow-up"),
       values = c("#008ECE",  "#59C7EB", "#CCEEF9")) 
  
  
  p <- ggdraw(p) +
    draw_line(
      x = c(0.008, 0.99),
      y = number,   # adjust up/down
      color = "black",
      size = 0.5
    )
  
  #plot graph and legend 
  legend_plot <- legend_plot +
    theme(
      plot.margin = margin(l = 0)
    )
  
  p <- plot_grid(p, legend_plot, nrow = 1, rel_widths = c(.75, 0.25))
  
  #save data 
  ggsave(
    paste0("/directory/", datout, ".eps"),
    p,
    device = "eps",
    width = 10,
    height = 6,
    dpi = 300
  )
}

g2 <- graph(
      dat = clinician,
      outcome = avg_mme,
      number = 0.17,
      datout = "trimmed",
      caption_text = paste(
      "<b>Figure 1 -</b> Impact of intervention on average mean clinician-weekly morphine milligram equivalents (MMEs).",
      "Y-axis values for pre-intervention<br>period are the per-clinician averages of the 1% trimmed mean clinician-weekly 
      MMEs for uncensored weeks. Y-axis values for intervention and<br> follow-up 
      periods are adjusted for percentage change using left-censored, mixed-effects regression coefficients (see <b>Supplementary Appendix</b>)."
      )
    )






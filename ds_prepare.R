# Library -----------------------------------------------------------------
library(ggmosaic)
library(ggrepel)
library(CHAID)
library(CGPfunctions)
library(knitr)



# Load data ---------------------------------------------------------------
df_working <- read_csv(FILE_DATA_RAW)
glimpse(df_working)

col_to_int <- c("ACLENGTH"
                ,"INTPLAN", "DATAPLAN"
                ,"OMCALL" ,"OTCALL" ,"NGCALL" ,"ICALL", "CUSCALL"
                ,"CHURN")

df_working %>%
    mutate_at(col_to_int, as.integer) ->
    df_working

glimpse(df_working)


# * data check point 0 ----------------------------------------------------
DATA_CHECKPOINT <- 0
save(df_working, file = FILE_DATA_CHECKPOINT(DATA_CHECKPOINT))
# load(FILE_DATA_CHECKPOINT(DATA_CHECKPOINT))



# EDA ---------------------------------------------------------------------
#Hmisc::describe(df_working)
DataExplorer::create_report(df_working,
                            output_dir = DIR_DOCPUT,
                            output_file = FILE_DATA_PROFILING_REPORT)



# Feature enginerring -----------------------------------------------------
LEVLEL_DATA_PKG <- c('0', '100M', '250M', '500M', '1G', '1.5G', '2G')
df_working$DATAGB <- factor(df_working$DATAGB,
                            ordered = TRUE, levels = LEVLEL_DATA_PKG)


df_working %>%
    mutate_at(c("INTPLAN", "DATAPLAN", "CHURN"),
                factor,
                labels = c("No", "Yes")) ->
    df_working

df_working$CUSCALL <- fct_recode(fct_lump_n(factor(df_working$CUSCALL,
                                                   ordered = TRUE),
                                            3),
                                'Call no' = '0',
                                'Call once' = '1',
                                'Call Twice' = '2',
                                'Call more than 2' = 'Other')



df_working %>%
    mutate_if(is.numeric,
              ~ ggplot2::cut_number(., n=5,labels = FALSE)) %>%
    mutate_if(is.integer,
              ~ factor(.,
                       labels = c("Low", "MedLow", "Medium", "MedHigh", "High"),
                       ordered = TRUE)) ->
    df_working

glimpse(df_working)

df_working %>%
    select(-ID) ->
    df_working


# * data check point 1 ----------------------------------------------------
DATA_CHECKPOINT <- 1
save(df_working, file = FILE_DATA_CHECKPOINT(DATA_CHECKPOINT))
# load(FILE_DATA_CHECKPOINT(DATA_CHECKPOINT))


# Plot churn vs CUSCALL ---------------------------------------------------
plot_working <- ggplot(data = df_working) +
                geom_mosaic(aes(x = product(CUSCALL), fill = CHURN))

df_cuscall_data <- ggplot_build(plot_working)$data[[1]]

df_cuscall_data %>%
    group_by_at(vars(ends_with("__CUSCALL"))) %>%
    mutate(NN = sum(.wt)) %>%
    mutate(pct = paste0(round(.wt/NN*100, 1), "%")) %>%
    pull(pct) ->
    section_label

plot_working +
    geom_text(data = df_cuscall_data,
              aes(x = (xmin + xmax)/2,
                  y = (ymin + ymax)/2,
                  label = section_label)) +
    labs(y = NULL,
         x = "Number of Customer Calls",
         title = "Amount of Churn by # of Customer Calls") +
     scale_y_continuous(labels = scales::label_percent(accuracy = 1.0),
                        breaks = seq(from = 0, to = 1, by = 0.10),
                        minor_breaks = seq(from = 0.05,
                                           to = 0.95,
                                           by = 0.10)) ->
    plot_working

plot_working


# Modeling ----------------------------------------------------------------
solution <- CHAID::chaid(CHURN ~ .,
                         data = df_working,
                         control = chaid_control(maxheight = 3))


print(solution)

plot(solution,
     main = "churn dataset, maxheight = 3",
     gp = gpar(lty = "solid", lwd = 2,fontsize = 8))



# Model performance -------------------------------------------------------
# Confusion matrix
caret::confusionMatrix(predict(solution), df_working$CHURN)


review_me <- CGPfunctions::chaid_table(solution)
kable(review_me[1:5, ])



# Business question -------------------------------------------------------
# Question #1:
# What percentage of customers are leaving if they have an international plan versus don’t?
#
# Answers:
# 14% versus 63%
review_me %>%
    select(nodeID:ruletext) %>%
    mutate(pctLeaving = Yes/NodeN * 100) %>%
    filter(parent == 1) %>%
    kable(digits = 1, caption = "Question #1 answer")


# Question #2:
# Can you provide an ordered list of where our churns are most likely to occur?
#
# Answers:
# For example while node # 20 has the most churn at 78% there’s only 30 some
# people in that node while #23 has slightly less churn and a lot more people
# to influence.
review_me %>%
    select(nodeID:split.variable) %>%
    mutate(pctLeaving = Yes/NodeN * 100) %>%
    filter(is.na(split.variable)) %>%
    select(-parent, -split.variable) %>%
    arrange(desc(pctLeaving)) %>%
    kable(digits = 1, caption = "Question #2 answer")



# charts ----------------------------------------------------------------
PlotXTabs2(df_working,
           CHURN, INTPLAN,
           bf.display = "sensible")

PlotXTabs2(df_working,
           INTPLAN,  CHURN,
           bf.display = "sensible")

df_working %>%
    filter(INTPLAN == "No") %>%
    PlotXTabs2(.,
               CUSCALL, CHURN,
               bf.display = "sensible")

df_working %>%
    filter(INTPLAN == "No") %>%
    PlotXTabs2(.,
               CHURN, CUSCALL,
               bf.display = "sensible",
               package = "ggthemes",palette = "Color Blind")

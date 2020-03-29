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
save(df_working, file = FILE_DATA_CHECKPOINT_0)
# load(FILE_DATA_CHECKPOINT_0)

fct_relevel

# EDA ---------------------------------------------------------------------
#Hmisc::describe(df_working)
#DataExplorer::create_report(df_working)



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



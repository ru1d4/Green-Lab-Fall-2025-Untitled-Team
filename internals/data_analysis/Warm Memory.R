install.packages(c("tidyverse", "ggplot2", "bestNormalize", "ARTool", "lmerTest", "xtable",
                  "dplyr", "viridis"))
install.packages("remotes")
install.packages("FSA")
install.packages("effsize")

library(effsize)
library(FSA)
library(tidyverse)
library(ggplot2)
library(bestNormalize)
library(ARTool)
library(lmerTest)
library(xtable)
library(remotes)
remotes::install_github("hrbrmstr/hrbrthemes")
library(dplyr)
library(viridis)
library(hrbrthemes)


dat_data <- read.csv("./run_table.csv") %>%
  select(
    benchmark,
    compilation,
    cold_start_energy, warm_start_energy,
    cold_start_cpu_util, warm_start_cpu_util,
    cold_start_duration, warm_start_duration,
    cold_start_memory_util, warm_start_memory_util
  ) %>%
  mutate(
    benchmark = str_remove(benchmark, "/original\\.py$"),
    benchmark = factor(benchmark),
    compilation = factor(compilation),
    cold_start_memory_util = cold_start_memory_util / (1024^2),
    warm_start_memory_util = warm_start_memory_util / (1024^2)
  )


# Data preparation
dat_dependent_var <- dat_data %>%
  select(benchmark, compilation, warm_start_memory_util) %>%
  mutate(
    benchmark = factor(benchmark),
    compilation = factor(compilation)
  )

# Min Max Mean Median SD
summary_stats <- dat_dependent_var %>%
  group_by(benchmark, compilation) %>%
  summarise(
    n = n(),
    min = min(warm_start_memory_util, na.rm = TRUE),
    max = max(warm_start_memory_util, na.rm = TRUE),
    mean = mean(warm_start_memory_util, na.rm = TRUE),
    median = median(warm_start_memory_util, na.rm = TRUE),
    sd = sd(warm_start_memory_util, na.rm = TRUE),
    .groups = "drop"
  )

# Descriptive stats (min, max, mean, median, sd):
print(summary_stats, n = Inf)


# Volin + Box
# Violin + Box (excluding numba just for plotting)
ggplot(
  dat_dependent_var %>% filter(compilation != "numba"),
  aes(x = compilation, y = warm_start_memory_util, fill = compilation)
) +
  geom_violin(alpha = 0.8, trim = FALSE) +
  geom_boxplot(width = 0.1, alpha = 0.3, outlier.size = 0.5) +
  scale_fill_viridis(discrete = TRUE, option = "C", begin = 0.2, end = 0.8) +
  facet_wrap(~ benchmark, nrow = 5, ncol = 2, scales = "free_y") +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(hjust = 0.5, vjust = 1, face = "bold", size = 14),
    axis.text.y = element_text(size = 12, face = "bold"),
    strip.text = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", size = 14),
    axis.title.y = element_text(size = 14, face = "bold"),
    axis.title.x = element_text(size = 14, face = "bold")
  ) +
  labs(
    x = "Compilation Tool",
    y = "Peak Memory Usage (MiB)"
  )


# Normality check
shapiro_results <- dat_dependent_var %>%
  group_by(benchmark, compilation) %>%
  summarise(
    n = n(),
    p_value = tryCatch(shapiro.test(warm_start_memory_util)$p.value, error = function(e) NA)
  ) %>%
  ungroup() %>%
  mutate(
    normal = ifelse(p_value > 0.05, "Yes", "No")
  )
# Normality Check Results
print(shapiro_results, n = Inf)

# Kruskal–Wallis test
kw_result <- dat_dependent_var %>%
  group_by(benchmark) %>%
  summarize(
    kw = list(kruskal.test(warm_start_memory_util ~ compilation, data = cur_data())),
    statistic = kw[[1]]$statistic,
    df = kw[[1]]$parameter,
    p_value = kw[[1]]$p.value
  ) %>%
  ungroup() %>%
  mutate(
    significant = ifelse(p_value < 0.05, "Yes", "No")
  )
# Kruskal-Wallis Test Results
print(kw_result, n = Inf)

# Post-hoc test
kw_result_dunn <- dat_dependent_var %>%
  group_by(benchmark) %>%
  summarize(
    dunn = list(dunnTest(
      warm_start_memory_util ~ compilation,
      data = cur_data(),
      method = "bonferroni"
    )),
    .groups = "drop"
  ) %>%
  mutate(
    comparisons = map(dunn, ~ .x$res %>%
      select(Comparison, Z, P.unadj, P.adj) %>%
      mutate(significant = ifelse(P.adj < 0.05, "Yes", "No")))
  ) %>%
  select(benchmark, comparisons) %>%
  unnest(comparisons)
# Dunn's post-hoc test results (Bonferroni-adjusted):
print(kw_result_dunn, n = Inf)


# quantify difference (% diff and cliff's delta)
# For each significant pair from Dunn's test, compute:
#   (a) percentage difference in medians
#   (b) Cliff's delta effect size (within each benchmark)

# 1) Build a lookup for each (benchmark, compilation): values + median
bench_series <- dat_dependent_var %>%
  group_by(benchmark, compilation) %>%
  summarize(
    values = list(warm_start_memory_util),
    median_energy = median(warm_start_memory_util),
    .groups = "drop"
  )

# 2) Start from significant Dunn pairs and attach both groups' vectors/medians
filtered_yes_dunn <- kw_result_dunn %>%
  filter(significant == "Yes") %>%
  separate(Comparison, into = c("group1", "group2"), sep = " - ") %>%
  # join group1 stats
  left_join(
    bench_series %>% rename(group1 = compilation,
                            values1 = values,
                            median1 = median_energy),
    by = c("benchmark", "group1")
  ) %>%
  # join group2 stats
  left_join(
    bench_series %>% rename(group2 = compilation,
                            values2 = values,
                            median2 = median_energy),
    by = c("benchmark", "group2")
  ) %>%
  # 3) Compute % median difference (relative to group2), and Cliff's delta
  rowwise() %>%
  mutate(
    n1 = length(values1),
    n2 = length(values2),
    pct_diff = 100 * (median2 - median1) / median2,
    cliffs_delta = tryCatch(
      effsize::cliff.delta(unlist(values1), unlist(values2), method = "unbiased")$estimate,
      error = function(e) NA_real_
    )
  ) %>%
  ungroup() %>%
  mutate(
    cliffs_interpretation = case_when(
      is.na(cliffs_delta)              ~ "NA",
      abs(cliffs_delta) < 0.147        ~ "negligible",
      abs(cliffs_delta) < 0.33         ~ "small",
      abs(cliffs_delta) < 0.474        ~ "medium",
      TRUE                             ~ "large"
    )
  ) %>%
  select(
    benchmark, group1, group2,
    n1, n2, median1, median2, pct_diff,
    cliffs_delta, cliffs_interpretation
  )

# Effect size (Cliff's delta) and percentage median difference for significant Dunn pairs:
print(filtered_yes_dunn, n = Inf)
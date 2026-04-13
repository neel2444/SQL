# ============================================================
#   OPTIMIZING SPORTS RETAIL REVENUE — R ANALYSIS
#   Nike vs Adidas: EDA, Visualisation & Statistical Analysis
#   Author: Neel Shah | Portfolio Project
#   Libraries: tidyverse, ggplot2, dplyr, corrplot, scales
# ============================================================

# ── 1. LOAD LIBRARIES ────────────────────────────────────────
library(tidyverse)
library(ggplot2)
library(dplyr)
library(scales)
library(corrplot)
library(ggcorrplot)

# Set a clean theme for all plots
theme_set(theme_minimal(base_size = 13) +
            theme(plot.title    = element_text(face = "bold", size = 15),
                  plot.subtitle = element_text(colour = "grey40"),
                  axis.title    = element_text(face = "bold"),
                  legend.position = "bottom"))


# ── 2. LOAD & MERGE DATA ─────────────────────────────────────
brands  <- read_csv("brands_v2.csv")
finance <- read_csv("finance.csv")
info    <- read_csv("info_v2.csv")
reviews <- read_csv("reviews_v2.csv")
traffic <- read_csv("traffic_v3.csv")

# Join all 5 tables on product_id
df <- brands  %>%
  inner_join(finance, by = "product_id") %>%
  inner_join(info,    by = "product_id") %>%
  inner_join(reviews, by = "product_id") %>%
  left_join(traffic,  by = "product_id") %>%
  filter(!is.na(brand), !is.na(revenue), !is.na(rating)) %>%
  mutate(
    # Price tier classification
    price_segment = case_when(
      listing_price < 42  ~ "Budget (<$42)",
      listing_price < 74  ~ "Mid-Range ($42-74)",
      listing_price < 130 ~ "Premium ($74-130)",
      TRUE                ~ "Elite (>$130)"
    ),
    price_segment = factor(price_segment,
      levels = c("Budget (<$42)","Mid-Range ($42-74)","Premium ($74-130)","Elite (>$130)")),

    # Discount tier
    discount_pct = discount * 100,
    disc_tier = case_when(
      discount == 0    ~ "No discount",
      discount <= 0.20 ~ "1-20% off",
      discount <= 0.40 ~ "21-40% off",
      TRUE             ~ "41%+ off"
    ),

    # Description length
    desc_length = nchar(coalesce(description, "")),
    desc_bucket = case_when(
      desc_length < 100 ~ "Short",
      desc_length < 200 ~ "Medium",
      desc_length < 300 ~ "Long",
      TRUE              ~ "Very Long"
    ),
    desc_bucket = factor(desc_bucket, levels = c("Short","Medium","Long","Very Long")),

    # Date features
    last_visited = as.POSIXct(last_visited),
    visit_month  = month(last_visited, label = TRUE)
  )

cat("✅ Data loaded:", nrow(df), "products\n")
cat("Brands:", table(df$brand), "\n")


# ── 3. EXPLORATORY DATA ANALYSIS ─────────────────────────────

## 3a. Summary statistics by brand
brand_summary <- df %>%
  group_by(brand) %>%
  summarise(
    n_products      = n(),
    total_revenue   = sum(revenue),
    avg_price       = mean(listing_price, na.rm = TRUE),
    avg_discount    = mean(discount_pct,  na.rm = TRUE),
    avg_rating      = mean(rating,        na.rm = TRUE),
    avg_reviews     = mean(reviews,       na.rm = TRUE),
    revenue_share   = round(sum(revenue)/sum(df$revenue)*100, 1)
  )
print(brand_summary)


# ── 4. VISUALISATIONS ────────────────────────────────────────

# Brand colours
brand_cols <- c("Adidas" = "#000000", "Nike"   = "#FF6B35")


## PLOT 1 — Revenue by Brand (bar chart)
p1 <- df %>%
  group_by(brand) %>%
  summarise(total_revenue = sum(revenue)) %>%
  ggplot(aes(x = brand, y = total_revenue, fill = brand)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = dollar(total_revenue, scale = 1e-6, suffix = "M")),
            vjust = -0.4, fontface = "bold", size = 5) +
  scale_fill_manual(values = brand_cols) +
  scale_y_continuous(labels = dollar_format(scale = 1e-6, suffix = "M")) +
  labs(title    = "Total Revenue: Adidas vs Nike",
       subtitle = "Adidas generates 93.5% of all revenue",
       x = NULL, y = "Total Revenue (USD millions)",
       fill = NULL) +
  theme(legend.position = "none")
print(p1)
ggsave("plot1_revenue_by_brand.png", p1, width = 8, height = 5, dpi = 150)


## PLOT 2 — Revenue by Price Segment (stacked bar)
p2 <- df %>%
  group_by(price_segment, brand) %>%
  summarise(avg_revenue = mean(revenue), .groups = "drop") %>%
  ggplot(aes(x = price_segment, y = avg_revenue, fill = brand)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = brand_cols) +
  scale_y_continuous(labels = dollar_format()) +
  labs(title    = "Average Revenue per Product by Price Segment",
       subtitle = "Elite products generate 80x more than budget products",
       x = "Price Segment", y = "Avg Revenue per Product ($)",
       fill = "Brand") +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
print(p2)
ggsave("plot2_revenue_by_segment.png", p2, width = 9, height = 5, dpi = 150)


## PLOT 3 — Rating Distribution by Brand (boxplot)
p3 <- df %>%
  ggplot(aes(x = brand, y = rating, fill = brand)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.15, fill = "white", outlier.size = 0.5) +
  geom_hline(yintercept = mean(df$rating), linetype = "dashed",
             colour = "grey40", linewidth = 0.8) +
  annotate("text", x = 2.5, y = mean(df$rating) + 0.1,
           label = paste("Overall avg:", round(mean(df$rating), 2)),
           colour = "grey40", size = 3.5) +
  scale_fill_manual(values = brand_cols) +
  labs(title    = "Rating Distribution: Adidas vs Nike",
       subtitle = "Adidas rates consistently higher (3.37 vs 2.79)",
       x = NULL, y = "Customer Rating (0–5)",
       fill = NULL) +
  theme(legend.position = "none")
print(p3)
ggsave("plot3_rating_distribution.png", p3, width = 7, height = 5, dpi = 150)


## PLOT 4 — Discount vs Revenue (scatter)
p4 <- df %>%
  filter(listing_price > 0) %>%
  ggplot(aes(x = discount_pct, y = revenue, colour = brand)) +
  geom_point(alpha = 0.3, size = 1.2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.2) +
  scale_colour_manual(values = brand_cols) +
  scale_y_continuous(labels = dollar_format()) +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  labs(title    = "Discount % vs Revenue per Product",
       subtitle = "Discounting shows negative correlation with revenue (r = -0.125)",
       x = "Discount (%)", y = "Revenue ($)",
       colour = "Brand") +
  coord_cartesian(ylim = c(0, 40000))
print(p4)
ggsave("plot4_discount_vs_revenue.png", p4, width = 9, height = 5, dpi = 150)


## PLOT 5 — Reviews vs Revenue (scatter with log scale)
p5 <- df %>%
  filter(reviews > 0, revenue > 0) %>%
  ggplot(aes(x = reviews, y = revenue, colour = brand)) +
  geom_point(alpha = 0.3, size = 1.2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.2) +
  scale_colour_manual(values = brand_cols) +
  scale_x_log10(labels = comma) +
  scale_y_log10(labels = dollar_format()) +
  labs(title    = "Review Count vs Revenue (log scale)",
       subtitle = "Reviews have the strongest correlation with revenue (r = 0.652)",
       x = "Number of Reviews (log scale)", y = "Revenue (log scale)",
       colour = "Brand")
print(p5)
ggsave("plot5_reviews_vs_revenue.png", p5, width = 9, height = 5, dpi = 150)


## PLOT 6 — Description Length vs Revenue (bar)
p6 <- df %>%
  filter(desc_length > 0) %>%
  group_by(desc_bucket) %>%
  summarise(avg_revenue = mean(revenue), avg_rating = mean(rating)) %>%
  ggplot(aes(x = desc_bucket, y = avg_revenue, fill = avg_rating)) +
  geom_col() +
  geom_text(aes(label = dollar(avg_revenue, accuracy = 1)),
            vjust = -0.4, fontface = "bold", size = 4) +
  scale_fill_gradient(low = "#FFB347", high = "#2ECC71",
                      name = "Avg Rating") +
  scale_y_continuous(labels = dollar_format()) +
  labs(title    = "Product Description Length vs Average Revenue",
       subtitle = "Very Long descriptions earn 10x more than Short descriptions",
       x = "Description Length", y = "Avg Revenue ($)")
print(p6)
ggsave("plot6_description_length.png", p6, width = 8, height = 5, dpi = 150)


## PLOT 7 — Correlation Heatmap
cor_data <- df %>%
  select(listing_price, sale_price, discount, revenue, rating, reviews) %>%
  filter(complete.cases(.)) %>%
  cor(method = "pearson")

p7 <- ggcorrplot(cor_data,
  method   = "circle",
  type     = "lower",
  lab      = TRUE,
  lab_size = 4,
  title    = "Correlation Matrix — Key Variables",
  ggtheme  = theme_minimal()) +
  labs(subtitle = "Reviews (0.65) is the strongest predictor of revenue")
print(p7)
ggsave("plot7_correlation_matrix.png", p7, width = 7, height = 6, dpi = 150)


## PLOT 8 — Top 10 Revenue Products
p8 <- df %>%
  arrange(desc(revenue)) %>%
  slice_head(n = 10) %>%
  mutate(product_label = str_wrap(product_name, 30)) %>%
  ggplot(aes(x = reorder(product_label, revenue),
             y = revenue, fill = brand)) +
  geom_col() +
  geom_text(aes(label = dollar(revenue, accuracy = 1)),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = brand_cols) +
  scale_y_continuous(labels = dollar_format(), expand = expansion(mult = c(0, 0.2))) +
  labs(title    = "Top 10 Revenue-Generating Products",
       subtitle = "Nike's Air Jordan 10 leads despite brand revenue gap",
       x = NULL, y = "Revenue ($)", fill = "Brand")
print(p8)
ggsave("plot8_top10_products.png", p8, width = 11, height = 6, dpi = 150)


## PLOT 9 — Monthly Traffic Trend
p9 <- df %>%
  filter(!is.na(visit_month)) %>%
  group_by(visit_month) %>%
  summarise(avg_revenue = mean(revenue)) %>%
  ggplot(aes(x = visit_month, y = avg_revenue, group = 1)) +
  geom_line(colour = "#2ECC71", linewidth = 1.5) +
  geom_point(colour = "#2ECC71", size = 3.5) +
  geom_area(fill = "#2ECC71", alpha = 0.15) +
  scale_y_continuous(labels = dollar_format()) +
  labs(title    = "Average Revenue by Month of Last Visit",
       subtitle = "Q3 (Jul–Sep) shows peak revenue — driven by summer sports season",
       x = "Month", y = "Avg Revenue ($)")
print(p9)
ggsave("plot9_monthly_trend.png", p9, width = 9, height = 5, dpi = 150)


# ── 5. STATISTICAL TESTS ─────────────────────────────────────

cat("\n===== STATISTICAL ANALYSIS =====\n\n")

## t-test: Is Adidas revenue significantly higher than Nike?
adidas_rev <- df %>% filter(brand == "Adidas") %>% pull(revenue)
nike_rev   <- df %>% filter(brand == "Nike")   %>% pull(revenue)

t_result <- t.test(adidas_rev, nike_rev, alternative = "greater")
cat("t-test: Adidas vs Nike Revenue\n")
cat("  p-value:", round(t_result$p.value, 6), "\n")
cat("  Result:", ifelse(t_result$p.value < 0.05, "SIGNIFICANT difference", "No significant difference"), "\n\n")

## Correlation: reviews vs revenue
cor_rev_reviews <- cor(df$reviews, df$revenue, use = "complete.obs")
cat("Correlation — Reviews vs Revenue:", round(cor_rev_reviews, 3), "\n")

cor_price_rev <- cor(df$listing_price, df$revenue, use = "complete.obs")
cat("Correlation — Listing Price vs Revenue:", round(cor_price_rev, 3), "\n")

cor_disc_rev  <- cor(df$discount, df$revenue, use = "complete.obs")
cat("Correlation — Discount vs Revenue:", round(cor_disc_rev, 3), "\n")

cor_desc_rev  <- cor(df$desc_length, df$revenue, use = "complete.obs")
cat("Correlation — Description Length vs Revenue:", round(cor_desc_rev, 3), "\n\n")

## Linear regression: Revenue drivers
model <- lm(revenue ~ listing_price + discount + rating + reviews + desc_length,
            data = df %>% filter(complete.cases(.)))
cat("Linear Regression: Revenue Drivers\n")
print(summary(model))


# ── 6. BUSINESS INSIGHTS SUMMARY ─────────────────────────────

cat("\n===== KEY BUSINESS INSIGHTS =====\n\n")
cat("1. Adidas: $11.5M revenue (93.5%) vs Nike: $802K (6.5%)\n")
cat("2. Reviews drive revenue most strongly (r = 0.652)\n")
cat("3. Listing price has 0.479 correlation with revenue\n")
cat("4. Discounting NEGATIVELY correlates with revenue (r = -0.125)\n")
cat("5. Very long descriptions generate 10x more revenue\n")
cat("6. Elite pricing (>$130) generates $9,818 avg/product vs $115 budget\n")
cat("7. Nike avg 7.46 reviews vs Adidas 48.76 — the growth opportunity\n")
cat("8. 354 Nike products have $0 listing price — missing revenue data\n")
cat("\nRECOMMENDATIONS:\n")
cat("  → Fix Nike's $0 listing prices (354 products = data quality issue)\n")
cat("  → Build Nike review count through post-purchase email campaigns\n")
cat("  → Reduce Adidas discounts — no-discount products earn more\n")
cat("  → Improve product descriptions for all brands\n")
cat("  → Expand Elite tier for Nike — their best products compete with Adidas top sellers\n")

cat("\n✅ Analysis complete. All plots saved.\n")

library(shiny)
library(bslib)
library(stringr)
library(dplyr)
library(tidyr)

# 1. LOAD DATA: Definitions and Image List
img_dir <- "www/" 
all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")

# Load Cleaned Definitions
df_raw <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)

# Standardize critical column names
colnames(df_raw)[1:4] <- c("level_1", "level_2", "img_class_name", "desc_general")

# Clean metadata: forward fill Level 1 categories but KEEP rows with empty img_class_name
df_defs <- df_raw %>%
  mutate(level_1 = na_if(level_1, "")) %>%
  fill(level_1) %>%
  # We only remove rows where Level 2 itself is missing
  filter(!is.na(level_2) & level_2 != "")

# 2. IMAGE FILENAME PARSING
parse_files <- function(files) {
  if(length(files) == 0) return(data.frame())
  data.frame(filename = files) %>%
    mutate(
      class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
      sample_num = str_extract(filename, "\\d+"),
      rest = str_extract(filename, "(?<=\\d_).*"),
      region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
      type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
      region_label = str_to_title(str_replace_all(region_id, "_", " "))
    )
}

file_data <- parse_files(all_files)

# 3. UI
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  titlePanel("IOLN Class Definitions Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("l1_input", "Select Level 1 Category:", 
                  choices = sort(unique(df_defs$level_1))),
      uiOutput("l2_select_ui"),
      uiOutput("region_select_ui"),
      hr(),
    ),
    
    mainPanel(
      uiOutput("eco_definition_card"),
      hr(),
      uiOutput("sample_grid"),
      uiOutput("fcc_texture_card")
    )
  )
)

# 4. SERVER
server <- function(input, output, session) {
  
  # This dropdown now shows ALL Level 2 classes regardless of image status
  output$l2_select_ui <- renderUI({
    req(input$l1_input)
    l2_choices <- df_defs %>%
      filter(level_1 == input$l1_input) %>%
      select(level_2, img_class_name) %>%
      distinct()
    
    # Use Level 2 as the ID to ensure it works even if img_class_name is NA
    selectInput("l2_input", "Select Level 2 Class:", 
                choices = l2_choices$level_2)
  })
  
  output$region_select_ui <- renderUI({
    req(input$l2_input)
    
    # Find the image class name associated with the selected Level 2 name
    target_img_class <- df_defs %>% 
      filter(level_2 == input$l2_input) %>% 
      pull(img_class_name) %>% 
      .[1]
    
    if(is.na(target_img_class) || target_img_class == "") {
      return(helpText("This class has no defined image mapping yet."))
    }
    
    available <- file_data %>%
      filter(class_id == target_img_class) %>%
      select(region_id, region_label) %>%
      distinct()
    
    if(nrow(available) == 0) return(helpText("No regions found with samples for this class."))
    
    selectInput("region_input", "Select Region:", 
                choices = setNames(available$region_id, available$region_label))
  })
  
  # Always shows the definition based on the Level 2 Name
  output$eco_definition_card <- renderUI({
    req(input$l2_input)
    row_match <- df_defs %>% filter(level_2 == input$l2_input) %>% slice(1)
    
    div(class = "p-4 mb-3 bg-light border rounded shadow-sm",
        tags$span(class = "badge bg-info mb-2", row_match$level_1),
        h3(row_match$level_2),
        h5("Ecological Definition", class = "mt-3 text-secondary"),
        p(row_match$desc_general)
    )
  })
  
  output$sample_grid <- renderUI({
    req(input$l2_input)
    
    target_img_class <- df_defs %>% 
      filter(level_2 == input$l2_input) %>% 
      pull(img_class_name) %>% 
      .[1]
    
    if(is.na(target_img_class) || target_img_class == "" || is.null(input$region_input)) {
      return(div(class="alert alert-secondary", "No sample imagery associated with this class yet."))
    }
    
    current_set <- file_data %>%
      filter(class_id == target_img_class, region_id == input$region_input)
    
    unique_samples <- sort(unique(current_set$sample_num))
    
    if (length(unique_samples) == 0) {
      return(div(class="alert alert-warning", "No sample images found for this class in the selected region."))
    }
    
    tagList(
      lapply(unique_samples, function(s) {
        variations <- current_set %>% filter(sample_num == s)
        div(class = "sample-row mb-5 pb-4 border-bottom",
            h4(paste("Sample ID:", s), class = "text-primary mb-3"),
            fluidRow(
              lapply(1:nrow(variations), function(i) {
                img <- variations[i, ]
                column(width = 3,
                       div(class = "card h-100 shadow-sm",
                           tags$img(src = img$filename, class = "card-img-top", style = "height: 200px; object-fit: cover;"),
                           div(class = "card-footer p-1 text-center bg-dark text-white", tags$small(toupper(img$type)))
                       )
                )
              })
            )
        )
      })
    )
  })
  
  output$fcc_texture_card <- renderUI({
    req(input$l2_input)
    row_match <- df_defs %>% filter(level_2 == input$l2_input) %>% slice(1)
    
    div(class = "p-4 mt-4 bg-light border rounded shadow-sm",
        h5("General FCC Interpretation", class = "text-secondary"),
        div(style = "white-space: pre-wrap; background-color: #fdfdfd; padding: 15px; border-left: 4px solid #0dcaf0; margin-bottom: 25px;",
            p(row_match$desc_fcc)),
        h5("Texture, Shape and Pattern", class = "text-secondary"),
        div(style = "white-space: pre-wrap; background-color: #f8f9fa; padding: 15px; border-left: 4px solid #6c757d;",
            p(row_match$desc_texture))
    )
  })
}

shinyApp(ui = ui, server = server)
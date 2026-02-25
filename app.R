# library(shiny)
# library(bslib)
# library(stringr)
# library(dplyr)
# library(tidyr)
# 
# # 1. SETUP: Images must be in 'www/'
# img_dir <- "www/" 
# all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")
# 
# # Robust Parsing Logic for multi-word classes and regions
# parse_geospatial_files <- function(files) {
#   df <- data.frame(filename = files) %>%
#     mutate(
#       # Extract Class: Everything before the first underscore+digit sequence
#       class_raw = str_extract(filename, "^.*?(?=_\\d+_)"),
#       class_label = str_replace_all(class_raw, "_", " "),
#       
#       # Extract Sample: The first number sequence
#       sample = str_extract(filename, "\\d+"),
#       
#       # Extract the 'Rest': Everything after the sample number
#       rest = str_extract(filename, "(?<=\\d_).*"),
#       
#       # Extract Region: Remove imagery suffix and clean underscores
#       region_raw = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
#       region_label = str_replace_all(region_raw, "_", " "),
#       
#       # Extract Type: The spectral/map category
#       type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)")
#     ) %>%
#     select(filename, class_label, sample, region_label, type)
#   
#   return(df)
# }
# 
# file_data <- parse_geospatial_files(all_files)
# 
# # 2. UI
# ui <- fluidPage(
#   theme = bs_theme(version = 5, bootswatch = "flatly"),
#   titlePanel("Geospatial Sample Comparison Grid"),
#   
#   sidebarLayout(
#     sidebarPanel(
#       selectInput("class_input", "Select Class:", 
#                   choices = sort(unique(file_data$class_label))),
#       
#       uiOutput("region_select_ui"),
#       
#       hr(),
#       helpText("Each row represents one Sample ID. Columns show different spectral composites.")
#     ),
#     
#     mainPanel(
#       uiOutput("sample_rows")
#     )
#   )
# )
# 
# # 3. SERVER
# server <- function(input, output, session) {
#   
#   # Dynamic Region UI based on Class
#   output$region_select_ui <- renderUI({
#     req(input$class_input)
#     available_regions <- file_data %>%
#       filter(class_label == input$class_input) %>%
#       pull(region_label) %>%
#       unique() %>%
#       sort()
#     
#     selectInput("region_input", "Select Region:", choices = available_regions)
#   })
#   
#   # Main Display Logic: Grouped by Sample
#   output$sample_rows <- renderUI({
#     req(input$class_input, input$region_input)
#     
#     # Filter data for the selected combination
#     filtered_data <- file_data %>%
#       filter(class_label == input$class_input, region_label == input$region_input)
#     
#     # Get unique samples to iterate through rows
#     unique_samples <- unique(filtered_data$sample)
#     
#     if (length(unique_samples) == 0) {
#       return(div(class = "alert alert-warning", "No data found for this selection."))
#     }
#     
#     # Create a list of fluidRows (one for each sample)
#     tagList(
#       lapply(unique_samples, function(s_id) {
#         # Find all variations for THIS sample
#         sample_files <- filtered_data %>% filter(sample == s_id)
#         
#         div(class = "mb-5 pb-3 border-bottom",
#             h4(paste("Sample ID:", s_id), class = "text-primary"),
#             fluidRow(
#               lapply(1:nrow(sample_files), function(i) {
#                 f_info <- sample_files[i, ]
#                 column(width = 3, # 4 items per row max, adjust as needed
#                        div(class = "card h-100 shadow-sm",
#                            tags$img(src = f_info$filename, class = "card-img-top", 
#                                     style = "height: 200px; object-fit: cover;"),
#                            div(class = "card-footer bg-light p-1 text-center",
#                                tags$small(strong(toupper(f_info$type)))
#                            )
#                        )
#                 )
#               })
#             )
#         )
#       })
#     )
#   })
# }
# 
# shinyApp(ui = ui, server = server)

# library(shiny)
# library(bslib)
# library(stringr)
# library(dplyr)
# library(tidyr)
# 
# # 1. SETUP: Load Images and the CSV Definitions
# img_dir <- "www/" 
# all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")
# 
# # --- DYNAMIC CSV LOADING ---
# # Skip the first 2 rows of metadata to reach the header row
# # 1. Read the file with fill=TRUE to prevent the "more columns than names" error
# # We skip the first 2 rows of text and use the 3rd row as the header
# df_raw <- read.csv("classes_definitions.csv", 
#                    skip = 2, 
#                    header = TRUE, 
#                    sep = ",", 
#                    fill = TRUE, 
#                    check.names = FALSE,
#                    stringsAsFactors = FALSE)
# 
# # 2. Clean the column names 
# # (The "Level 1" and "Level 2" columns are usually 1 and 2)
# colnames(df_raw)[1:3] <- c("level_1", "level_2", "desc_general")
# 
# # 3. Process the data for the Shiny App
# df_defs <- df_raw %>%
#   # Fill the merged 'Level 1' cells (e.g., Forest) down to every row
#   fill(level_1) %>%
#   # Remove any completely empty rows that may have been 'filled'
#   filter(!is.na(level_2) & level_2 != "") %>%
#   # Select only the columns we need for the UI
#   select(level_1, level_2, desc_general)
# 
# # 2. FILENAME PARSING LOGIC
# parse_geospatial_files <- function(files) {
#   data.frame(filename = files) %>%
#     mutate(
#       # Extract Class ID: matches the prefix used in filenames (e.g., 'evergreen')
#       class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
#       # Extract Sample ID
#       sample = str_extract(filename, "\\d+"),
#       # Extract Region and Imagery Type
#       rest = str_extract(filename, "(?<=\\d_).*"),
#       region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
#       type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
#       # Clean labels
#       class_label = str_to_title(str_replace_all(class_id, "_", " ")),
#       region_label = str_to_title(str_replace_all(region_id, "_", " "))
#     )
# }
# 
# file_data <- parse_geospatial_files(all_files)
# 
# # 3. UI
# ui <- fluidPage(
#   theme = bs_theme(version = 5, bootswatch = "flatly"),
#   titlePanel("Dynamic Geospatial Mosaic Explorer"),
#   
#   sidebarLayout(
#     sidebarPanel(
#       selectInput("class_input", "Select Class:", 
#                   choices = setNames(sort(unique(file_data$class_id)), 
#                                      sort(unique(file_data$class_label)))),
#       uiOutput("region_select_ui"),
#       hr(),
#       helpText("Definitions are pulled directly from classes_definitions.csv")
#     ),
#     
#     mainPanel(
#       uiOutput("class_info_panel"),
#       uiOutput("sample_grid")
#     )
#   )
# )
# 
# # 4. SERVER
# server <- function(input, output, session) {
#   
#   # Reactive Region selector
#   output$region_select_ui <- renderUI({
#     req(input$class_input)
#     available <- file_data %>%
#       filter(class_id == input$class_input) %>%
#       select(region_id, region_label) %>%
#       distinct()
#     
#     selectInput("region_input", "Select Region:", 
#                 choices = setNames(available$region_id, available$region_label))
#   })
#   
#   # DYNAMIC DEFINITION LOGIC
#   output$class_info_panel <- renderUI({
#     req(input$class_input)
#     
#     # Logic to find the correct row in the CSV based on the class_id
#     # Since CSV uses labels like '1.2. Evergreen forest', we match by keyword
#     row_match <- df_defs %>%
#       filter(grepl(input$class_input, level_2, ignore.case = TRUE)) %>%
#       slice(1)
#     
#     definition <- if(nrow(row_match) > 0) row_match$desc_general else "Definition not found in CSV."
#     
#     div(class = "p-4 mb-4 bg-light border rounded shadow-sm",
#         h3(str_to_title(str_replace_all(input$class_input, "_", " "))),
#         p(definition)
#     )
#   })
#   
#   # GRID DISPLAY (One row per Sample ID)
#   output$sample_grid <- renderUI({
#     req(input$class_input, input$region_input)
#     
#     filtered <- file_data %>%
#       filter(class_id == input$class_input, region_id == input$region_input)
#     
#     samples <- unique(filtered$sample)
#     
#     tagList(
#       lapply(samples, function(s) {
#         sample_rows <- filtered %>% filter(sample == s)
#         
#         div(class = "mb-5",
#             h4(paste("Sample ID:", s), class = "border-bottom pb-2"),
#             fluidRow(
#               lapply(1:nrow(sample_rows), function(i) {
#                 item <- sample_rows[i, ]
#                 column(width = 3,
#                        div(class = "card h-100",
#                            tags$img(src = item$filename, class = "card-img-top"),
#                            div(class = "card-footer p-1 text-center bg-dark text-white",
#                                tags$small(toupper(item$type)))
#                        )
#                 )
#               })
#             )
#         )
#       })
#     )
#   })
# }
# 
# shinyApp(ui = ui, server = server)

library(shiny)
library(bslib)
library(stringr)
library(dplyr)
library(tidyr)

# 1. LOAD DATA: Read the cleaned CSV and list images
# Images should be in a folder named 'www/' relative to app.R
img_dir <- "www/" 
all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")

# Load Class Definitions (Headers: Level 1, Level 2, Description Ecological - general)
df_defs <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)
colnames(df_defs)[1:3] <- c("level_1", "level_2", "desc_general")

# 2. IMAGE FILENAME PARSING
# Logic for: classname_samplenumber_region_imagetype.png
# Matches multi-word classes/regions and extracts the numeric sample
parse_files <- function(files) {
  data.frame(filename = files) %>%
    mutate(
      # Class: Text before the first number sequence (e.g., 'mosaic_of_use')
      class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
      
      # Sample: The first numeric sequence (e.g., '116')
      sample_num = str_extract(filename, "\\d+"),
      
      # Extract everything after the sample number
      rest = str_extract(filename, "(?<=\\d_).*"),
      
      # Region: Text between sample number and the imagery suffix
      region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
      
      # Imagery Type (e.g., 'fcc543', 'rgb', 'basemap')
      type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
      
      # Create readable labels for UI
      class_label = str_to_title(str_replace_all(class_id, "_", " ")),
      region_label = str_to_title(str_replace_all(region_id, "_", " "))
    )
}

file_data <- parse_files(all_files)

# 3. UI
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  titlePanel("IOLN Class definitions"),
  
  sidebarLayout(
    sidebarPanel(
      # Dropdown for Class
      selectInput("class_input", "Select Class:", 
                  choices = setNames(sort(unique(file_data$class_id)), 
                                     sort(unique(file_data$class_label)))),
      
      # Dynamic dropdown for Regions
      uiOutput("region_select_ui"),
      
      hr(),
      helpText("Images are grouped by Sample ID. Definitions are pulled from your CSV.")
    ),
    
    mainPanel(
      # Dynamic Class Definition Section
      uiOutput("definition_card"),
      hr(),
      # Row-based Sample Gallery
      uiOutput("sample_grid")
    )
  )
)

# 4. SERVER
server <- function(input, output, session) {
  
  # Filter available regions based on the selected class
  output$region_select_ui <- renderUI({
    req(input$class_input)
    available <- file_data %>%
      filter(class_id == input$class_input) %>%
      select(region_id, region_label) %>%
      distinct()
    
    selectInput("region_input", "Select Region:", 
                choices = setNames(available$region_id, available$region_label))
  })
  
  # DYNAMIC DEFINITION: Fuzzy match filename class to CSV Level 2
  output$definition_card <- renderUI({
    req(input$class_input)
    
    # Try to find a match in the Level 2 column using the filename prefix
    row_match <- df_defs %>%
      filter(grepl(input$class_input, level_2, ignore.case = TRUE) | 
               grepl(str_replace_all(input$class_input, "_", " "), level_2, ignore.case = TRUE)) %>%
      slice(1)
    
    if(nrow(row_match) > 0) {
      div(class = "p-4 mb-4 bg-light border rounded shadow-sm",
          tags$span(class = "badge bg-info mb-2", row_match$level_1),
          h3(row_match$level_2),
          p(class = "lead", row_match$desc_general)
      )
    } else {
      div(class = "alert alert-secondary", "No matching definition found in classes_definitions.csv")
    }
  })
  
  # GALLERY: One row per unique Sample Number
  output$sample_grid <- renderUI({
    req(input$class_input, input$region_input)
    
    # Filter for the class/region combination
    current_set <- file_data %>%
      filter(class_id == input$class_input, region_id == input$region_input)
    
    unique_samples <- sort(unique(current_set$sample_num))
    
    if (length(unique_samples) == 0) return(div("No imagery found."))
    
    # Generate a horizontal row for every Sample ID
    tagList(
      lapply(unique_samples, function(s) {
        # Find all spectral/map variations for this specific coordinate
        variations <- current_set %>% filter(sample_num == s)
        
        div(class = "mb-5 pb-4 border-bottom",
            h4(paste("Sample ID:", s), class = "text-primary mb-3"),
            fluidRow(
              lapply(1:nrow(variations), function(i) {
                img <- variations[i, ]
                column(width = 3, # 4 images per row
                       div(class = "card h-100 shadow-sm",
                           tags$img(src = img$filename, class = "card-img-top", 
                                    style = "height: 180px; object-fit: cover;"),
                           div(class = "card-footer p-1 text-center bg-dark text-white",
                               tags$small(toupper(img$type)))
                       )
                )
              })
            )
        )
      })
    )
  })
}

shinyApp(ui = ui, server = server)
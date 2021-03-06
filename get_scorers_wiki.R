library(rvest)
library(tidyverse)

load(file = "rows.Rdata")

get_scorers <- function(paths){
  first_read <- TRUE
  for (path in paths){
    events <- path %>%
      read_html(encoding = "UTF-8") %>%
      html_elements(".fgoals") %>%
      html_text() %>%
      str_remove_all("Report") %>%
      str_remove_all("\\(pen.\\)") %>%
      str_remove_all("\\'") %>%
      str_split("\\\n") %>%
      unlist() 
    
    e_scorers <- tibble("event" = events) %>%
      filter(grepl("^[A-Za-z]+", event)) %>%
      filter(!grepl("o.g.", event)) %>%
      mutate(goals = str_count(event, "\\,"),
             goals = goals + 1,
             player = str_remove_all(event, "[0-9]"),
             player = str_remove_all(player, "\\n"),
             player = str_remove_all(player, "\\,"),
             player = str_remove_all(player, "\\+"),
             player = str_trim(player),
             player = str_replace(player, "F. Torres", "Torres"))
    
    if (first_read) {
      scorers <- e_scorers
      first_read <- FALSE
    } else {
      scorers <- bind_rows(scorers, e_scorers)
    }
  }
  scorers <- scorers %>%
    group_by(player) %>%
    summarise(goals = sum(goals))
}

group_scorers <- get_scorers(
  c("https://en.wikipedia.org/wiki/UEFA_Euro_2020_Group_A",
    "https://en.wikipedia.org/wiki/UEFA_Euro_2020_Group_B",
    "https://en.wikipedia.org/wiki/UEFA_Euro_2020_Group_C",
    "https://en.wikipedia.org/wiki/UEFA_Euro_2020_Group_D",
    "https://en.wikipedia.org/wiki/UEFA_Euro_2020_Group_E", 
    "https://en.wikipedia.org/wiki/UEFA_Euro_2020_Group_F"
    )
)

scorers_results <- scorers %>%
  gather(veikkaaja, player) %>%
  distinct(player) %>%
  separate(
    player,
    sep = " ",
    into = c("first", "last"),
    remove = FALSE
  ) %>%
  left_join(group_scorers, by = c("last" = "player")) %>%
  select(player, goals) %>%
  replace_na(list(goals = 0))
  
scorers_results %>%
  write_delim("scorers_results.txt", delim = "\t")

rm(scorers_results, group_scorers)

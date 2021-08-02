#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

library(shinyjs)
library(ravana)
library(ggplot2)


ravana::init_cluster('Ravana', settingspath = 'C:/R')
sql <- "SELECT nodename, status, count(taskuid) FROM mappedtasks WHERE clustername=?p1 GROUP BY nodename, status ORDER BY nodename"
SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = 'Ravana')
res      <- DBI::dbGetQuery(Ravana$connection, SQL)



ui <- pageWithSidebar(
    #shinyjs::useShinyjs(),
    
    headerPanel(h1("RAVANA Task Dashboard", align = "center")),
    sidebarPanel(width = 0, id="sidebar"),
    mainPanel(width = 12,shinyjs::useShinyjs(),
        tags$head(tags$style("#distPlot{height:80vh !important;}")),
        plotOutput("distPlot")
    )
)





# Define server logic required to draw a histogram
server <- function(input, output) {


    output$distPlot <- renderPlot({
        par(mar=c(1, 1, 1, 1))
        
        shinyjs::runjs("function reload_page() {window.location.reload();setTimeout(reload_page, 1000);}
                        setTimeout(reload_page, 10000);
                       ")
        
        ravana::init_cluster('Ravana', settingspath = 'C:/R')
        sql <- "SELECT * FROM job_stats(?p1)"
        SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = 'Ravana')
        res      <- DBI::dbGetQuery(Ravana$connection, SQL)
        ravana::disconnect()
        res$count_of_jobs <- as.numeric(res$count_of_jobs)
        ggplot(data = res, aes(x = task , y = count_of_jobs, fill = job_status   )) +  geom_bar(stat='identity')        + theme(text = element_text(size=20))        + theme(legend.position="bottom") + labs(x = "Function - Tasks - Node", y= "Count of Sub-Tasks", fill = "Task Status")
        
    })
    
    shinyjs::runjs(
        "function reload_page() {
  window.location.reload();
  setTimeout(reload_page, 3000);
}
setTimeout(reload_page, 3000);
")
}

# Run the application 
shinyApp(ui = ui, server = server)

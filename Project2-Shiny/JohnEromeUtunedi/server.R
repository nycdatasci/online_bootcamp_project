#server


server = function(input, output) {
  dataInput1 = reactive({
    g2 = list(showcountries = T, countrycolor = toRGB("black"), showland = T, landcolor = toRGB("grey90"))
    plot_geo(locationmode = "country names") %>% add_trace(data = filter(Country_data,Year == input$sliderRef), 
                                                           z = ~Refugee.Status, color = ~Refugee.Status, 
                                                           text = ~paste("Country: ", Country, "<br />Refugee Total: ", Refugee.Status),
                                                           locations = ~Country) %>% layout(geo = g2) %>% colorbar(len = 0.75)
    #CountryFilterMap(data3 = input$sliderRef)
  })
  output$plot1_ref = renderPlotly({
    dataInput1()
    #ggplotly(dataInput1())
   })
  dataInput2 = reactive({
    CountryFilterBar.Plotly(Year_val = input$sliderRef1, height = input$SliderRef2, arrange = input$radio_Ref)
    #CountryFilterBar(fil = input$sliderRef1, height = input$SliderRef2, arrange = input$radio_Ref)
  })
  output$plot2_ref = renderPlotly({
     dataInput2()
  })
  dataInput3 = reactive({
    
    if(length(input$selectCountryRef) != 0) {
      CountryFilterUsrInteract.Plotly(var = input$selectCountryRef)
      #temp = filter(Country_data, Country %in% c(input$selectCountryRef), Refugee.Status!=0)
      #temp = ggplot(data = temp) + geom_line(aes(x = Year, y = Refugee.Status, color = Country)) +
       # theme(legend.justification = c(0,0),legend.position = c(0,0))
    } else {
      CountryFilterUsrInteract.Plotly(var = "")
      #temp = ggplot()
      }
  })
  output$plot3_ref = renderPlotly({
    dataInput3() 
  })
  dataInput4 = reactive({
    ContinentFilterBar.Plotly(fil = input$SliderRef3, height = input$SliderRef4, arrange = input$radio_Ref1)
  })
  output$plot4_ref = renderPlotly({
    dataInput4()
  })
  
  dataInput5 = reactive({
    if(length(input$selectContRef) != 0) {
      ContinentFilterUsrInteract.Plotly(var = input$selectContRef)  
      #temp = filter(Continent_data, Continent %in% c(input$selectContRef))
      #temp = ggplot(data = temp) + geom_line(aes(x = Year, y = Refugee.Status, color = Continent)) + 
      #  theme(legend.justification = c(0,0),legend.position = c(0,0))
    } else {
      ContinentFilterUsrInteract.Plotly(var = "")
      #temp = ggplot()
      }    
  })
  output$plot5_ref = renderPlotly({
    dataInput5() 
  })
  
  dataInput16 = reactive({
    CountryFilterTotal.Plotly(data = Country_data, amt = input$SliderRef6, type = input$radio_Ref2)
  })
  
  output$plot6_ref = renderPlotly({
    dataInput16()
  })
  
  dataInput17 = reactive({
    CountryFilterSum.Plotly(data = Country_data, amt = input$SliderRef6, type = input$radio_Ref2)
  })
  
  output$plot7_ref = renderPlotly({
    dataInput17()
  })
  
  dataInput18 = reactive({
    ContinentFilterSum.Plotly(amt = input$SliderRef7, type = input$radio_Ref3)
  })
  output$plot8_ref = renderPlotly({
    dataInput18()
  })
  
  dataInput19 = reactive({
    ContinentFilterTotal.Plotly(amt = input$SliderRef7, type = input$radio_Ref3)
  })
  output$plot9_ref = renderPlotly({
    dataInput19()
  })
  
  dataInput20 = reactive({
    Total.Plotly()
  })
  output$plot10_ref = renderPlotly({
    dataInput20()
  })
## Defensive Asylum  
  dataInput6 = reactive({
    g2 = list(showcountries = T, countrycolor = toRGB("black"), showland = T, landcolor = toRGB("grey90"))
    plot_geo(locationmode = "country names") %>% add_trace(data = filter(Country_Def_data,Year == input$sliderRef_Def), 
                                                           z = ~Defensive.Asylum, color = ~Defensive.Asylum, 
                                                           text = ~paste("Country: ", Country, "<br />Defensive Asylum Total: ", Defensive.Asylum),
                                                           locations = ~Country) %>% layout(geo = g2) %>% colorbar(len = 0.75)
    
    #CountryFilterMap.Def(data3 = input$sliderRef_Def)
  })
  output$plot1_ref_Def = renderPlotly({
    dataInput6()
    #ggplotly(dataInput1())
  })
  dataInput2_Def = reactive({
    CountryFilterBar_Def.Plotly(Year_val = input$sliderRef1_Def, height = input$SliderRef2_Def, arrange = input$radio_Ref_Def)
    #CountryFilterBar(fil = input$sliderRef1, height = input$SliderRef2, arrange = input$radio_Ref)
  })
  output$plot2_ref_Def = renderPlotly({
    dataInput2_Def()
  })
  dataInput3_Def = reactive({
    
    if(length(input$selectCountryRef_Def) != 0) {
      CountryFilterUsrInteract_Def.Plotly(var = input$selectCountryRef_Def)
      #temp = filter(Country_data, Country %in% c(input$selectCountryRef), Refugee.Status!=0)
      #temp = ggplot(data = temp) + geom_line(aes(x = Year, y = Refugee.Status, color = Country)) +
      # theme(legend.justification = c(0,0),legend.position = c(0,0))
    } else {
      CountryFilterUsrInteract_Def.Plotly(var = "")
      #temp = ggplot()
    }
  })
  output$plot3_ref_Def = renderPlotly({
    dataInput3_Def() 
  })
  dataInput4_Def = reactive({
    ContinentFilterBar_Def.Plotly(fil = input$SliderRef3_Def, height = input$SliderRef4_Def, arrange = input$radio_Ref1_Def)
  })
  output$plot4_ref_Def = renderPlotly({
    dataInput4_Def()
  })
  dataInput5_Def = reactive({
    if(length(input$selectContRef_Def) != 0) {
      ContinentFilterUsrInteract_Def.Plotly(var = input$selectContRef_Def) 
      #temp = filter(Cont_Def_data, Continent %in% c(input$selectContRef_Def))
      #temp = ggplot(data = temp) + geom_line(aes(x = Year, y = Defensive.Asylum, color = Continent)) + 
      #  theme(legend.justification = c(0,0),legend.position = c(0,0))
    } else {
      ContinentFilterUsrInteract_Def.Plotly(var = "") 
      #temp = ggplot()
      }    
  })
  output$plot5_ref_Def = renderPlotly({
    dataInput5_Def() 
  })
  
  dataInput16_Def = reactive({
    CountryFilterTotal_Def.Plotly(amt = input$SliderRef6_Def, type = input$radio_Ref2_Def)
  })
  
  output$plot6_ref_Def = renderPlotly({
    dataInput16_Def()
  })
  
  dataInput17_Def = reactive({
    CountryFilterSum_Def.Plotly(amt = input$SliderRef6_Def, type = input$radio_Ref2_Def)
  })
  
  output$plot7_ref_Def = renderPlotly({
    dataInput17_Def()
  })
  
  dataInput18_Def = reactive({
    ContinentFilterSum_Def.Plotly(amt = input$SliderRef7_Def, type = input$radio_Ref3_Def)
  })
  output$plot8_ref_Def = renderPlotly({
    dataInput18_Def()
  })
  
  dataInput19_Def = reactive({
    ContinentFilterTotal_Def.Plotly(amt = input$SliderRef7_Def, type = input$radio_Ref3_Def)
  })
  output$plot9_ref_Def = renderPlotly({
    dataInput19_Def()
  })
  
  dataInput20_Def = reactive({
    Total_Def.Plotly()
  })
  output$plot10_ref_Def = renderPlotly({
    dataInput20_Def()
  })
  
## Affirmative Asylym 
  dataInput11 = reactive({
    g2 = list(showcountries = T, countrycolor = toRGB("black"), showland = T, landcolor = toRGB("grey90"))
    plot_geo(locationmode = "country names") %>% add_trace(data = filter(Country_Aff_data,Year == input$sliderRef_Aff), 
                                                           z = ~Affirmative.Asylum, color = ~Affirmative.Asylum, 
                                                           text = ~paste("Country: ", Country, "<br />Affirmartive Asylum Total: ", Affirmative.Asylum),
                                                           locations = ~Country) %>% layout(geo = g2) %>% colorbar(len = 0.75)
    
    #CountryFilterMap.Aff(data3 = input$sliderRef_Aff)
  })
  output$plot1_ref_Aff = renderPlotly({
    dataInput11()
    #ggplotly(dataInput1())
  })
  dataInput2_Aff = reactive({
    CountryFilterBar_Aff.Plotly(Year_val = input$sliderRef1_Aff, height = input$SliderRef2_Aff, arrange = input$radio_Ref_Aff)
    #CountryFilterBar(fil = input$sliderRef1, height = input$SliderRef2, arrange = input$radio_Ref)
  })
  output$plot2_ref_Aff = renderPlotly({
    dataInput2_Aff()
  })
  dataInput3_Aff = reactive({
    
    if(length(input$selectCountryRef_Aff) != 0) {
      CountryFilterUsrInteract_Aff.Plotly(var = input$selectCountryRef_Aff)
      #temp = filter(Country_data, Country %in% c(input$selectCountryRef), Refugee.Status!=0)
      #temp = ggplot(data = temp) + geom_line(aes(x = Year, y = Refugee.Status, color = Country)) +
      # theme(legend.justification = c(0,0),legend.position = c(0,0))
    } else {
      CountryFilterUsrInteract_Aff.Plotly(var = "")
      #temp = ggplot()
    }
  })
  output$plot3_ref_Aff = renderPlotly({
    dataInput3_Aff() 
  })
  dataInput4_Aff = reactive({
    ContinentFilterBar_Aff.Plotly(fil = input$SliderRef3_Aff, height = input$SliderRef4_Aff, arrange = input$radio_Ref1_Aff)
  })
  output$plot4_ref_Aff = renderPlotly({
    dataInput4_Aff()
  })
  dataInput5_Aff = reactive({
    if(length(input$selectContRef_Def) != 0) {
      ContinentFilterUsrInteract_Aff.Plotly(var = input$selectContRef_Aff) 
      #temp = filter(Cont_Def_data, Continent %in% c(input$selectContRef_Def))
      #temp = ggplot(data = temp) + geom_line(aes(x = Year, y = Defensive.Asylum, color = Continent)) + 
      #  theme(legend.justification = c(0,0),legend.position = c(0,0))
    } else {
      ContinentFilterUsrInteract_Aff.Plotly(var = "") 
      #temp = ggplot()
    }    
  })
  output$plot5_ref_Aff = renderPlotly({
    dataInput5_Aff() 
  })
  
  dataInput16_Aff = reactive({
    CountryFilterTotal_Aff.Plotly(amt = input$SliderRef6_Aff, type = input$radio_Ref2_Aff)
  })
  
  output$plot6_ref_Aff = renderPlotly({
    dataInput16_Aff()
  })
  
  dataInput17_Aff = reactive({
    CountryFilterSum_Aff.Plotly(amt = input$SliderRef6_Aff, type = input$radio_Ref2_Aff)
  })
  
  output$plot7_ref_Aff = renderPlotly({
    dataInput17_Aff()
  })
  
  dataInput18_Aff = reactive({
    ContinentFilterSum_Aff.Plotly(amt = input$SliderRef7_Aff, type = input$radio_Ref3_Aff)
  })
  output$plot8_ref_Aff = renderPlotly({
    dataInput18_Aff()
  })
  
  dataInput19_Aff = reactive({
    ContinentFilterTotal_Aff.Plotly(amt = input$SliderRef7_Aff, type = input$radio_Ref3_Aff)
  })
  output$plot9_ref_Aff = renderPlotly({
    dataInput19_Aff()
  })
  
  dataInput20_Aff = reactive({
    Total_Aff.Plotly()
  })
  output$plot10_ref_Aff = renderPlotly({
    dataInput20_Aff()
  })
}
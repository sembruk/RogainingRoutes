--------------------------------------------
--! Configuration
--------------------------------------------
return {
   course_data_filename = "./in/coords.csv",
   splits_filename      = "./in/splits.htm",
   map_filename         = "./in/map.jpg",
   broken_cps           = "./in/broken.csv",
   map_dpi              = 72,
   map_scale_factor     = 14170,
   rotateAngle          = -10, ---< in degrees
   out_dir              = "./out",
   title                = nil, -- if nil from splits html
   title = 'Рогейн &laquo;Оп, Лыткарино!&raquo;, л/п Лыткарино, 24.09.2016.',

   start_x              = 728,
   start_y              = 1167,

   groups = {
      ["8 часов бегом"]         = {start = "12:15:00", "М8БО","Ж8БО","ММ8БК","МЖ8БК","ЖЖ8БК",},
      ["6 часов бегом"]         = {start = "12:15:00", "М6БО","Ж6БО","ММ6БК","МЖ6БК","ЖЖ6БК",},
      ["4 часа бегом"]          = {start = "12:15:00", "М4БО","Ж4БО"},
      ["3 часа бегом"]          = {start = "12:15:00", "М3БО","Ж3БО"},
      ["2 часа бегом"]          = {start = "12:15:00", "2БО",},
      ["1 час бегом"]           = {start = "12:15:00", "1БО",},

      ["6 часов на велосипеде"] = {start = "12:00:00", "М6ВО","Ж6ВО","ММ6ВК","МЖ6ВК","ЖЖ6ВК",},
      ["3 часа на велосипеде"]  = {start = "12:00:00", "М3ВО","Ж3ВО"},
      ["2 часа на велосипеде"]  = {start = "12:00:00", "2ВО",},
      ["1 час на велосипеде"]   = {start = "12:00:00", "1ВО",},
   },

   javascript_map_scale = 1,

   display_team_name    = true,

   sfr_split_field_name_by_index = {
      "number",
      "id",
      "second_name",
      "first_name",
      "year_of_birth",
      "name",
      "result",
      "time",
      "_",
   },
}


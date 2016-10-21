--------------------------------------------
--! Configuration
--------------------------------------------
return {
   course_data_filename = "./in/coords.csv",
   splits_filename      = "./in/splits.htm",
   map_filename         = "./in/map.jpg",
   map_dpi              = 120,
   map_scale_factor     = 14170,
   start_time           = "12:00:00",
   out_dir              = "./out",
   title                = nil, -- if nil from splits html

   start_x              = 1211,
   start_y              = 1943,

   groups = {
      ["8 часов бегом"]         = {"М8БО","Ж8БО","ММ8БК","МЖ8БК","ЖЖ8БК",},
      ["6 часов бегом"]         = {"М6БО","Ж6БО","ММ6БК","МЖ6БК","ЖЖ6БК",},
      ["3 часа бегом"]          = {"М3БО","Ж3БО"},
      ["2 часа бегом"]          = {"2БО",},
      ["1 час бегом"]           = {"1БО",},

      ["6 часов на велосипеде"] = {"М6ВО","Ж6ВО","ММ6ВК","МЖ6ВК","ЖЖ6ВК",},
      ["3 часа на велосипеде"]  = {"М3ВО","Ж3ВО"},
      ["2 часа на велосипеде"]  = {"2ВО",},
      ["1 час на велосипеде"]   = {"1ВО",},
   },

   javascript_map_scale = 0.8,
   rotateAngle          = -10, ---< in degrees

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


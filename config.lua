--------------------------------------------
--! Configuration
--------------------------------------------
return {
   map_filename = "../../mega/vvpg2015/routes/map_vcg2015.jpg",
   course_data_filename = "../../mega/vvpg2015/routes/coordinates.txt",
   splits_filename = "../../mega/vvpg2015/results/splitsGr.htm",
   out_dir = "./out",
   title = nil,
   groups = {"6лнн", "6лнй", "6ян", "6фн"},
   start_time = "12:00:00",
   map_dpi = 75,
   javascript_map_scale = 1,
   rotateAngle = 19.5, ---< in degrees

   display_team_name = true,

   sfr_split_field_name_by_index = {
      "number",
      "id",
      "second_name",
      "first_name",
      "name",
      --"subgroup",
      "city",
      "result",
      "time",
      "position",
      --"_"
   },
}


--------------------------------------------
--! Configuration
--------------------------------------------
return {
   course_data_filename = "./in/coords.csv",
   splits_filename      = "./in/splits.htm",
   map_filename         = "./in/map.jpg",
   broken_cps           = "./in/broken.csv",
   map_dpi              = 72,
   map_scale_factor     = 15000,
   rotateAngle          = 0, ---< in degrees
   out_dir              = "./out",
   title                = nil, -- if nil from splits html
   --title = '������ &laquo;��, ���������!&raquo;, �/� ���������, 24.09.2016.',

   start_x              = 251,
   start_y              = 654,

   groups = {
      ["8 ����� �����"]         = {start = "11:15:00", "�8��","�8��","��8��","��8��","��8��",},
      ["6 ����� �����"]         = {start = "11:15:00", "�6��","�6��","��6��","��6��","��6��",},
      ["4 ���� �����"]          = {start = "11:15:00", "�4��","�4��","4��_�","4��_�","4��_�","4��_�","4��_�"},
      ["3 ���� �����"]          = {start = "11:15:00", "�3��","�3��"},
      ["2 ���� �����"]          = {start = "11:15:00", "2��","2��_�","2��_�",},
      ["1 ��� �����"]           = {start = "11:15:00", "1��",},

      ["6 ����� �� ����������"] = {start = "11:00:00", "�6��","�6��","��6��","��6��","��6��",},
      ["3 ���� �� ����������"]  = {start = "11:00:00", "�3��","�3��","3��_�","3��_�","3��_�"},
      ["2 ���� �� ����������"]  = {start = "11:00:00", "2��",},
      ["1 ��� �� ����������"]   = {start = "11:00:00", "1��",},
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


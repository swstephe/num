
-- MODULE: num.sql
-- exceptions
insert into lang_except values("farsi","num",1,"1","یک");
insert into lang_except values("farsi","num",2,"2","دو");
insert into lang_except values("farsi","num",3,"3","سه");
insert into lang_except values("farsi","num",4,"4","چهار");
insert into lang_except values("farsi","num",5,"5","پنج");
insert into lang_except values("farsi","num",6,"6","شش");
insert into lang_except values("farsi","num",7,"7","هفت");
insert into lang_except values("farsi","num",8,"8","هشت");
insert into lang_except values("farsi","num",9,"9","نه");
insert into lang_except values("farsi","num",10,"10","ده");
insert into lang_except values("farsi","num",11,"11","یازده");
insert into lang_except values("farsi","num",12,"12","دوازده");
insert into lang_except values("farsi","num",13,"13","سیزده");
insert into lang_except values("farsi","num",14,"14","چهارده");
insert into lang_except values("farsi","num",15,"15","پانزده");
insert into lang_except values("farsi","num",16,"16","شانزده");
insert into lang_except values("farsi","num",17,"17","هفده");
insert into lang_except values("farsi","num",18,"18","هجده");
insert into lang_except values("farsi","num",19,"19","نوزده");
insert into lang_except values("farsi","num",20,"20","بیست");
insert into lang_except values("farsi","num",21,"30","سی");
insert into lang_except values("farsi","num",22,"40","چهل");
insert into lang_except values("farsi","num",23,"50","پنجاه");
insert into lang_except values("farsi","num",24,"60","شصت");
insert into lang_except values("farsi","num",25,"70","هفتاد");
insert into lang_except values("farsi","num",26,"80","هشتاد");
insert into lang_except values("farsi","num",27,"90","نود");
insert into lang_except values("farsi","num",28,"100","صد");
insert into lang_except values("farsi","num",29,"200","دویشت");
insert into lang_except values("farsi","num",30,"500","پانصد");
insert into lang_except values("farsi","num",31,"1000","هزار");
insert into lang_except values("farsi","num",32,"1000000","ميليون");
insert into lang_except values("farsi","num",33,"1000000000","میلیارد");

-- rules
insert into lang_rule values("farsi","num",1,"(\d)(\d)"););
-- num($1+"0"),"و",num($2)
insert into lang_commands values("farsi","num",1,1,"M",2);
insert into lang_commands values("farsi","num",1,2,"P",1);
insert into lang_commands values("farsi","num",1,3,"C","num");
insert into lang_commands values("farsi","num",1,4,"Q","و");
insert into lang_commands values("farsi","num",1,5,"M",1);
insert into lang_commands values("farsi","num",1,6,"Q","0");
insert into lang_commands values("farsi","num",1,7,"+",null);
insert into lang_commands values("farsi","num",1,8,"P",1);
insert into lang_commands values("farsi","num",1,9,"C","num");
insert into lang_commands values("farsi","num",1,10,"J",null);

insert into lang_rule values("farsi","num",2,"(\d)00"););
-- num($1)+"صد"
insert into lang_commands values("farsi","num",2,1,"M",1);
insert into lang_commands values("farsi","num",2,2,"P",1);
insert into lang_commands values("farsi","num",2,3,"C","num");
insert into lang_commands values("farsi","num",2,4,"Q","صد");
insert into lang_commands values("farsi","num",2,5,"+",null);

insert into lang_rule values("farsi","num",3,"(\d)(\d{2})"););
-- num($1+"00"),num($2)
insert into lang_commands values("farsi","num",3,1,"M",2);
insert into lang_commands values("farsi","num",3,2,"P",1);
insert into lang_commands values("farsi","num",3,3,"C","num");
insert into lang_commands values("farsi","num",3,4,"M",1);
insert into lang_commands values("farsi","num",3,5,"Q","00");
insert into lang_commands values("farsi","num",3,6,"+",null);
insert into lang_commands values("farsi","num",3,7,"P",1);
insert into lang_commands values("farsi","num",3,8,"C","num");
insert into lang_commands values("farsi","num",3,9,"J",null);

insert into lang_rule values("farsi","num",4,"(\d{1,3})000"););
-- num($1)+"هزار"
insert into lang_commands values("farsi","num",4,1,"M",1);
insert into lang_commands values("farsi","num",4,2,"P",1);
insert into lang_commands values("farsi","num",4,3,"C","num");
insert into lang_commands values("farsi","num",4,4,"Q","هزار");
insert into lang_commands values("farsi","num",4,5,"+",null);

insert into lang_rule values("farsi","num",5,"(\d{1,3})(\d{3})"););
-- num($1+"000"),num($2)
insert into lang_commands values("farsi","num",5,1,"M",2);
insert into lang_commands values("farsi","num",5,2,"P",1);
insert into lang_commands values("farsi","num",5,3,"C","num");
insert into lang_commands values("farsi","num",5,4,"M",1);
insert into lang_commands values("farsi","num",5,5,"Q","000");
insert into lang_commands values("farsi","num",5,6,"+",null);
insert into lang_commands values("farsi","num",5,7,"P",1);
insert into lang_commands values("farsi","num",5,8,"C","num");
insert into lang_commands values("farsi","num",5,9,"J",null);

insert into lang_rule values("farsi","num",6,"(\d{1,3})000000"););
-- num($1)+"ميليون"
insert into lang_commands values("farsi","num",6,1,"M",1);
insert into lang_commands values("farsi","num",6,2,"P",1);
insert into lang_commands values("farsi","num",6,3,"C","num");
insert into lang_commands values("farsi","num",6,4,"Q","ميليون");
insert into lang_commands values("farsi","num",6,5,"+",null);

insert into lang_rule values("farsi","num",7,"(\d{1,3})(\d{6})"););
-- num($1+"000000"),num($2)
insert into lang_commands values("farsi","num",7,1,"M",2);
insert into lang_commands values("farsi","num",7,2,"P",1);
insert into lang_commands values("farsi","num",7,3,"C","num");
insert into lang_commands values("farsi","num",7,4,"M",1);
insert into lang_commands values("farsi","num",7,5,"Q","000000");
insert into lang_commands values("farsi","num",7,6,"+",null);
insert into lang_commands values("farsi","num",7,7,"P",1);
insert into lang_commands values("farsi","num",7,8,"C","num");
insert into lang_commands values("farsi","num",7,9,"J",null);

insert into lang_rule values("farsi","num",8,"(\d{1,3})000000000"););
-- num($1)+"میلیارد"
insert into lang_commands values("farsi","num",8,1,"M",1);
insert into lang_commands values("farsi","num",8,2,"P",1);
insert into lang_commands values("farsi","num",8,3,"C","num");
insert into lang_commands values("farsi","num",8,4,"Q","میلیارد");
insert into lang_commands values("farsi","num",8,5,"+",null);

insert into lang_rule values("farsi","num",9,"(\d{1,3})(\d{9})"););
-- num($1+"000000000"),num($2)
insert into lang_commands values("farsi","num",9,1,"M",2);
insert into lang_commands values("farsi","num",9,2,"P",1);
insert into lang_commands values("farsi","num",9,3,"C","num");
insert into lang_commands values("farsi","num",9,4,"M",1);
insert into lang_commands values("farsi","num",9,5,"Q","000000000");
insert into lang_commands values("farsi","num",9,6,"+",null);
insert into lang_commands values("farsi","num",9,7,"P",1);
insert into lang_commands values("farsi","num",9,8,"C","num");
insert into lang_commands values("farsi","num",9,9,"J",null);


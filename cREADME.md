This is Caleb's/Developer's Readme file.
This app, Melzers Condtion Tracking App (better name pending)
Is a project to not only showcase my skills as a software designer
but to also aid my wife and others in tracking their physical condition on their desired devices.

This app will allow users to take a breif snapshot of their current state. It is inteded to create records of the physical condition, but also has the capacity to track mental state as well in a limited capacity, mental health is just as important as physical well being.

This app is intended to track the following
Fatuige
Pain tollerance
wake and sleep hours
blood sugar levels (single point per entry)
Heart health
Water intake
meals and medications consumed
Activites performed
symptoms and feelings

All entries are stored in a localy placed database where the app resideds, thats where the database resides; tablet or phone or desktop.
Placing the database onto the device of choice limits outsideers accesibility to the users information, and since this is a health oriented app, this is a major feature of the app.
The database will reside inside of the documents folder of the device, for the need to be extracted for whatever need, in the event a export feature is implemented the database will be relocated to the app itself(planned).

There is a review feature but is currently limited to individual dates, at this time a export feture is planned but not implemented

Planed Project completion for initial state is end of the summer. 
App testing and tweaking planned for the fall season.
Submition for Google Play planned at the end of the year.
this is the ideal timeline.

Development timeline/progress:

May 2025:
App creation started

June 2025:
New build documented on github, .gitignore and cleanups performed, dates look more like a calendar form, still tending to the app/database connection, adjusting the calendar date positions to relate to the shown month.
Shifted the database query point to the 'timestamp' column and away from 'day' column. a quirk in the review entries button was discovered.
Fixed the carryover from the review mode button. It was retaining a state as months were changed, implemented an auto shut off for review mode when chaning dates. Implemented a way to select a particular month and year instead of having to cycle months. Also created a gradient "path" from one designated color to another, so as the number of entries are made on days, the richer the next color becomes. Also affected the flare icon it now retains the yellow color that is underneath, It is a good contrast against the review indigo color as well.
Made the Month and Year, an opperable element alowing a user to select month and year without having to cycle through months. Quite a useful feature if it is needed.

July 2025
7/3 Did some major restructuring of the project code, the Main.dart file was getting to heavy so the things like color control and the bulk of the calendarWidget got moved to their own file structure.
The Flare Icon that the user will see, emerges at 10 datapoints but as more entries are placec beyond 10 the larger that Flare Icon will grow. This signifies not only tie importance and urgency of the date, but in the event that there are a string of days with litteraly flare ups, you can visualy see which was the worse day. In talking with the wife/client, a end of the month review was discussed. at this point, a monthly review of the 3 most prevelant symptoms would be a good idea. We will see how we will implement that after establishing the review display.
The wife expressed a desire to track water consumption and I happily agreeed to include that in the database and the entry screen. I am dragging my feet on the database reporting feature of the app, I have some idea ast to what I would like to see it as, and the functionality of it, but we will get on it soon, I think before I tackle the report, we need as much as we need to see in the database first. Should consult the wife on that aspect.
Only having about 4 hours of sleep, and looking off the wife seeing me pale and feeling me as cold decded to check on my Health, my blood preasure. heart rate, and oxygen levels. I asked if we should include that in the tracker, she said sure. so I did, I also tweaked the helper text in the entry screen and modified the visual behavior of the review button.
Trimmed some fat and made a discovery that imports can piggyback on other imports.
7/11 Renamed the main.dart file to main_Screen.dart, this was done to give more emphasis that this is the place that users will spend the majority of their app time in. It is also the hub of most of the functionalities of the app.
We finaly have a decent looking review feature to display individiual entries, something to look into next is to possibly condense the days entries into a singular card. somehting to look into soon.
After a full day of not having internet acess, oh what sadness, a late-night coding sesh has added a reasonable sleep time tracker, Idealy it will give an impression of your sleep paterns in a simple X hours structure.
With the behavior adjusted we are complete with "vision 1" what was going on is that the review entries button was not waiting for a date selection and automaticaly dumping the months entries on screen, that was corrected. then the dates were only redirecting users to the entry screen, but was not observing the fact taht the app was in "review entries mode" aditionaly, now that it is all ironed out, the user can transition between dates and the exit of review mode, will clear the card area of the app. the final key to vision 1 to being complete on windows machines.

The next task is to get 'vision 1' ready for android devices.
July 18 2025
Made sure some of the back of the house codeing is complted, havent really modified the code for the app just yet. Implemented device file structure access for the app, will concider including an export feature while making android-oriented adjustments.
July 22 2025
Just got the coded portions of the app ready to be android device compatable. we will next be making it available for the field testers.
July 25 2025
Yesterday, I put the first build put onto the wife/clients phone and she immediately came across a behavioral issue that wasnt accounted for, the sleep/wake times were blocking database entries if they were left empty or null. It got handled with fallback values and a response for the cards last night and build 1.1.0+1 was generated to test that behavior resolution, upon reflection this morning, The card response needed to be adjusted to accomodate entries that could be placed when the sleep values are ignored, such as a mid-day entry. build 1.1.0+2
July 26 2025
Saw an issue with the sleep time fallback handler, and spent the good part of the day remedying the errant behavior, several measures had to take place but things got ironed out. build 1.1.1+1
The function of evaluating the hours slept as a total length of time, was problematic so I have decided to just use the values inserted by the user. maybe at a later date i will return to the function. it took a moment but the new time format is good and understandable.
August 2025
Wife would like to see the ability to track periods, and edit/delete entries. I am going to get started with the period tracker, its already fleshed out in my mind.
8/3/2025
With the period marking feature completed, I have implemneted an enviroment where the snapshot card can be tapped and 2 options are present, to edit the entry or to delete it in the database. The next feature to be added is the latter, I am performing this addetion first because i think it would be the easiest to implement out of the two.|
8/11/2025
With the inclusion of being able to delete entries in the app, something has broken with the app when used by the wifes phone. The app is not saving entries into the databse, this is only isolated to her phone however. It behaves properly in my phone, and two emulated phone eniroments, one being her phone runing android 14.
8/15/2025
Included a card where a user can input and store daily infomration, they should persist till they are replaced with other information. I did not include a way to clear the line as i do not want the app to block the user from adding values or encounter an automatic deletion issue.
~8/30/2025
I was taking a shower one morning before work and realized that the app was not monitoring its name sake, the spoons. The spoons is a concept quite similar to a energy bar, wehre every day a person has so much energy to spend each day. In this case the descritping item is a quantiy of spoons, hence the name of Spoonie. Since I could not find an Icon specificaly looking like an actul spoon, I had to create my own Icon to implement as a spoon slider. Although I think it looks more like a table tennis paddle more than a spoon but it is what I went with, the wife thinks its cute and if it is cute then it stays.
Septmber 2025
9/1/2025
Decided that the contents of the main.dart file was getting too large again, decided to migrate the daily Information/Medications card to its own dart file, as well as the database review cards, ligthening the line count of the main.dart file.
9/18/2025
Finding out that Mellisa and I both have been neglecting the spoonie app, I have decided to actully implement a notification gently asking if the user is willing to add an entry. As to be not so intrusive and being thoughtful of the users attention i have set the notification interval to 3 days. I think 3 days is a respectable durration between notifications.
9/26/2025
Wife made an observation that the cardio related information does not have a report in the cards. Since this cardio question has multiple fields in one string, I might break it down to two lines, one to define how the information is arragend and output it on a line below the definition.
9/20/2025
I have implemented the output of the heart health information, it is deployed
October 2025
10/07/2025
I added Melissa's Icon as the app icon for android devices. I had to change the size of the image but it looks decent on my phone. Im glad it was an easy addtion. and I am one step closer to setting up for closed testing with google. I think if everything plays out like i thoinkk it will I will meet my goal for being on google play at the turn of the year.




Current desires from the wife:


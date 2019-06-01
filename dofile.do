
//	For convenience, so that you don't have to hit spacebar when there's more than one screen of output
set more off

//	Create variables
destring actual, replace
gen overenrolled = actual > maximum

//	calculates the predicted probability for each department (dc) that one of the classes is overenrolled in the spring
regress overenrolled i.fall i.dc, vce(robust)

//	Predicts the probability each department overenrolled its courses, regardless of term
margins dc

//gives us the average of the changes in probability for fall versus spring of overenrolling, across all of the departments
regress overenrolled i.fall##i.dc, vce(robust)

margins, dydx(fall) //runs predictive margins on the betas (the derivatives of each term)

margins, dydx(fall) over(dc) //gives us the difference within each department in their probability of overenrolling in fall versus spring (how much more likely within a department are they to overenrolled in fall vs spring)

margins dc //tells us which departments are most likely to overenroll, regardless of semester

gen ayear = substr(term,1,4) //this part includes academic-year fixed effects by taking the first four characters of each term
destring ayear, replace
tab ayear

tab class_name maximum if regexm(class_name,"Honors") //this part drops Honors Seminars and Senior Research (many of these are coded to zero and mess with our analysis)
gen exclude = regexm(class_name,"Honors")


//	Linear probability model predicting probability of overenrollment, controlling for year and department FE, for classes with 8 or more cap
regress overenrolled i.fall##i.dc i.ayear if maximum>7, vce(robust)
margins if maximum>7, dydx(fall) //excludes classes with a maximum of 8 or less


//	We think the probability of overenrolling the course to 20 or more will be substantially lower in the fall
gen over20 = actual > 20 
gen max19 = maximum < 20
gen bw = maximum > 13 & maximum < 26


/* 	The model below is called a Regression Discontinuity Design. It allows us to test
	whether classes directly below the cutoff (here, a class size of 19 vs 20) have a
	different probability of enrolling in fall versus spring, for classes that are more
	similar to each other in size. Note that there are a lot of classes capped at 18,
	and a lot that are capped at 25, so I decided on a symmetric "band" of classes between
	max 14 (max size for most seminar-size classrooms) and max 25. */
gen runningVariable = maximum-20 // This controls for any linear trend in probability of overenrollment as fn of class size, in general
regress overenrolled fall##max19 max19#c.runningVariable i.dc i.ayear if bw==1 & exclude==0

/*	The margins command below evaluates how probability of overenrollment changes for fall versus spring
	and evaluates that both for classes subject to the higher-stakes "Under20" (max 19) cutoff, versus those
	just above the cutoff with max class size of 20 to 25.	You'll see there's a larger negative coefficient for
	classes where the original max class size was between 14 and 19. */
margins if exclude==0 & bw==1, dydx(fall) at(max19=(0 1))


/*	This regression allows us to test whether courses with max enrollment under 20
	are less likely to overenroll in the fall to 20 or more students. You could try
	different minimum values... probably class of 18 that overenrolls is more likely
	to get to 20 than a class set at 12 max 											*/
regress over20 i.fall##i.maximum i.ayear i.dc if bw==1 & max19==1 & exclude==0
/*	The margins command below tells us, for each possible class max size, the difference in probability
	of overenrolling with actual enrollment 20 or higher, for fall versus spring.	*/
margins if exclude==0 & bw==1 & max19==1, dydx(fall) at(maximum=(14(1)19))



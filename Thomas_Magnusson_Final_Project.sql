DROP SCHEMA PUBLIC CASCADE;
CREATE SCHEMA PUBLIC;

-- Thomas Magnusson
-- Database Management - Final Project
-- Alan Labouseur

-- Corvis - Custom Varsity Athlete Food Delivery

-- All the people in the database, including but not limited to
--  Users, which are Athletes and Coaches
--  Contacts, who are the contact for a given Delivery
--  KitchenManagers, who manage the kitchens (obviously)
CREATE TABLE People (
  pid SERIAL PRIMARY KEY,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  email TEXT NOT NULL
);



-- People who use the Corvis website or mobile app.
-- Limited to: Athletes and Coaches.
CREATE TABLE Users (
  pid INTEGER PRIMARY KEY REFERENCES People(pid),
  password TEXT NOT NULL
);

-- Coaches are the primary users of Corvis.
-- They can order food for everyone.
CREATE TABLE Coaches (
  pid INTEGER PRIMARY KEY REFERENCES Users(pid)
);

-- Athletes select a meal out of a bunch of possible meals
-- generated based on their position on a sport.
CREATE TABLE Athletes (
  pid INTEGER PRIMARY KEY REFERENCES Users(pid),
  birthdate DATE NOT NULL,
  heightInches INTEGER NOT NULL,
  weightPounds INTEGER NOT NULL,

  -- Athletes participate in either male or female sports, appropriate dichotomy.
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female'))
);

-- Like, you know, Baseball and all that.
CREATE TABLE Sports (
  name TEXT PRIMARY KEY
);

-- Positions (for a sport)
CREATE TABLE Positions (
  name TEXT NOT NULL PRIMARY KEY
);

-- Relates sports to a position.
-- Seems like it's not a many to many relation,
-- but the same position name might be
-- in different sports.
CREATE TABLE SportPositions (
  sportName TEXT NOT NULL REFERENCES Sports(name),
  positionsName TEXT NOT NULL REFERENCES Positions(name),

  PRIMARY KEY(sportName, positionsName)
);

-- Like Da Bears
CREATE TABLE Teams (
  tid SERIAL PRIMARY KEY,
  sport TEXT REFERENCES Sports(name),
  name TEXT NOT NULL
);

-- The coaches for a given team.
CREATE TABLE TeamStaff (
  coachPid INTEGER REFERENCES Coaches(pid),
  tid INTEGER REFERENCES Teams(tid),

  PRIMARY KEY(coachPid, tid)
);

-- A specific athlete on a team,
-- and what that athlete's position is.
CREATE TABLE Roster (
  athletePid INTEGER NOT NULL REFERENCES Athletes(pid),
  tid INTEGER NOT NULL REFERENCES Teams(tid),
  position TEXT NOT NULL REFERENCES Positions(name),

  PRIMARY KEY(athletePid, tid)
);

-- END SPORTS STUFF --

-- BEGIN RANDOM STUFF

-- Corvis only has a finite number
-- of available zip codes for delivery.
CREATE TABLE ValidZipCodes (
  zipCode TEXT NOT NULL PRIMARY KEY
);

-- Addresses for kitchens and
-- deliveries.
CREATE TABLE Addresses (
  aid SERIAL NOT NULL PRIMARY KEY,
  address TEXT NOT NULL,
  address2 TEXT, -- nullable because not all addresses have second line
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  zipCode TEXT NOT NULL REFERENCES ValidZipCodes(zipCode)
);

-- END RANDOM STUFF

-- BEGIN FOOD STUFF --

-- Like oz, dollops, slices, etc.
CREATE TABLE ServingUnits (
  unit TEXT NOT NULL PRIMARY KEY
);

-- For a meal. Base serving size because an Ingredient like Ham
-- might require a multiple amount of the base serving size, which
-- would probably be 1 oz or something like that. Other Ingredients,
-- like Gatorade, would have base serving size as 1 and
-- the serving unit as 8oz. Bottle.
CREATE TABLE Ingredients (
  iid SERIAL PRIMARY KEY,
  name TEXT NOT NULL,

  baseServingSize DECIMAL NOT NULL,
  baseServingUnit TEXT NOT NULL REFERENCES ServingUnits(unit),

  calories INTEGER NOT NULL,

  carbGrams DECIMAL NOT NULL,
  proteinGrams DECIMAL NOT NULL,
  fatGrams DECIMAL NOT NULL
);

-- Promotional meals, like "Delicious Ham Sandwich"
-- See IngredientsInMeals to find out what are in these meals.
CREATE TABLE Meals (
  mid SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

-- The ingredients that go into a meal.
CREATE TABLE IngredientsInMeals (
  iid INTEGER NOT NULL REFERENCES Ingredients(iid),
  mid INTEGER NOT NULL REFERENCES Meals(mid),

  -- Nullable, null if this ingredient is a variable one,
  -- meaning the serving size can be tweaked to fit a position's
  -- ratio profile.
  numberOfServings DECIMAL,

  PRIMARY KEY(iid, mid)
);

-- Gluten Free, Nut Free, etc.
CREATE TABLE Accommodations (
  name TEXT NOT NULL PRIMARY KEY
);

-- A meal that satisfies an Accommodation, like gluten free.
CREATE TABLE AccommodativeMeals (
  mid INTEGER NOT NULL REFERENCES Meals(mid),
  accommodation TEXT NOT NULL REFERENCES Accommodations(name),

  PRIMARY KEY(mid, accommodation)
);



-- BEGIN DELIVERY STUFF --

-- Coaches place Orders, each of which can have many deliveries
CREATE TABLE Orders (
  tid INTEGER NOT NULL REFERENCES Teams(tid),
  placedByPid INTEGER NOT NULL REFERENCES Coaches(pid),
  placedAt TIMESTAMP NOT NULL,

  -- The id for Stripe, an online payment service.
  -- Paying with a card online generates and id.
  stripeChargeId TEXT NOT NULL UNIQUE,

  PRIMARY KEY(tid, placedByPid, placedAt)
);

-- The timeframe the athletes will be eating the meals before (or after)
-- the event in which they are participating.
CREATE TABLE EatTime (
  hoursBeforeGame INTEGER NOT NULL PRIMARY KEY
);

-- A person who is a contact for a delivery in case the kitchens
-- need to contact a representative on the team besides the coach.
-- A contact can actually be a coach in this database design :).
CREATE TABLE Contacts (
  pid INTEGER NOT NULL PRIMARY KEY REFERENCES People(pid),
  phone TEXT NOT NULL
);

-- A delivery represents an event to be delivered to.
-- Part of a single Order.
CREATE TABLE Deliveries (
  did SERIAL NOT NULL PRIMARY KEY,

  eventTime TIMESTAMP NOT NULL,

  orderTid INTEGER NOT NULL,
  orderPlacedByPid INTEGER NOT NULL,
  orderPLacedAt TIMESTAMP NOT NULL,
  FOREIGN KEY (orderTid, orderPlacedByPid, orderPlacedAt)
  REFERENCES Orders(tid, placedByPid, placedAt),

  numGenericMeals INTEGER NOT NULL,
  hoursBeforeGame INTEGER NOT NULL REFERENCES EatTime (hoursBeforeGame),
  contactPid INTEGER NOT NULL REFERENCES Contacts(pid),
  addressAid INTEGER NOT NULL REFERENCES Addresses(aid)

);

-- An Athlete selects a meal for a given delivery. This is the meal
-- they will receive for that delivery.
CREATE TABLE Selections (
  athletePid INTEGER NOT NULL REFERENCES Athletes(pid),
  did INTEGER NOT NULL REFERENCES Deliveries(did),

  -- nullable, if the athlete has not made a selection yet.
  mid INTEGER DEFAULT NULL REFERENCES Meals(mid),
  madeAt TIMESTAMP NOT NULL,

  PRIMARY KEY(athletePid, did)
);

-- Ingredients can be converted to custom ingredients,
-- in order to fit the ratio of the specific athlete's position.
-- Ham, for example, can be sliced to any weight, therefore it can be
-- used to further balance a meal's ratio, rather than a bottle of gatorade,
-- which cannot be "split" (it has a set number of calories and macronutrients).
CREATE TABLE CustomMealIngredients (
  selectionAthletePid INTEGER NOT NULL,
  selectionDid INTEGER NOT NULL,
  FOREIGN KEY (selectionAthletePid, selectionDid)
  REFERENCES Selections(athletePid, did),

  iid INTEGER NOT NULL REFERENCES Ingredients(iid),
  numberOfServings DECIMAL NOT NULL DEFAULT 1,

  PRIMARY KEY (selectionAthletePid, selectionDid, iid)
);

-- Which meals are meant for which time frames.
-- Lots of pasta 6 hours before a game is better than 2 hours after.
CREATE TABLE MealTimeframes (
  hoursBeforeGame INTEGER NOT NULL REFERENCES EatTime (hoursBeforeGame),
  mid INTEGER NOT NULL REFERENCES Meals(mid),

  PRIMARY KEY(hoursBeforeGame, mid)
);



-- END DELIVERY STUFF

-- BEGIN KITCHEN STUFF$

-- Who manages the kitchens?
CREATE TABLE KitchenManagers (
  pid INTEGER NOT NULL PRIMARY KEY REFERENCES People(pid),

  -- Nullable, a directory where we might not know the phone number of a manager
  phone TEXT
);

-- Where the food is processed. Needed to provide contact information
-- to anyone needing further assistance.
CREATE TABLE Kitchens (
  kid SERIAL NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  aid INTEGER NOT NULL REFERENCES Addresses(aid),
  phone TEXT NOT NULL
);

-- Managers and the kitchens they manage.
CREATE TABLE ManagersOfKitchens (
  managerPid INTEGER NOT NULL REFERENCES KitchenManagers(pid),
  kid INTEGER NOT NULL REFERENCES Kitchens(kid),

  PRIMARY KEY(managerPid, kid)
);

-- END KITCHEN STUFF

-- BEGIN MAGIC STUFF

-- The ratios of macronutrients necessary for a given
-- position within a sport for a meal.
-- Also changes based on the eat time (when the athletes
-- will consume the meal in relation to the event they are
-- competing in).
CREATE TABLE Ratios (
  position TEXT NOT NULL,
  sport TEXT NOT NULL,
  FOREIGN KEY (position, sport)
  REFERENCES SportPositions(positionsName, sportName),

  hoursBeforeGame INTEGER NOT NULL REFERENCES EatTime (hoursBeforeGame),

  carbsMultiplier DECIMAL NOT NULL,
  proteinMultiplier DECIMAL NOT NULL,
  fatMultiplier DECIMAL NOT NULL,

  PRIMARY KEY(position, sport, hoursBeforeGame)
);

-- ENG MAGIC STUFF

-- People
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (1, 'Tom', 'Magnusson', 'tommagnuss@gmail.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (8, 'Tom', 'Magnusson', 'tommagnuss@exmaple.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (9, 'Meat', 'Head', 'meat@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (10, 'Block', 'Head', 'block@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (11, 'Hot', 'Head', 'hot@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (12, 'Timmy', 'Foley', 'timmy@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (13, 'Brian', 'Damp', 'brian@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (14, 'Jack', 'Potenza', 'jack@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (15, 'Spencer', 'Foley', 'spencer@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (16, 'Matt', 'Clyne', 'matt@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (17, 'Daisy', 'Chu', 'daisy@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (18, 'Tanya', 'Elizabeth', 'tanya@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (19, 'Constantina', 'Marsden', 'dina@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (20, 'Taylor', 'Vahey', 'taylor@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (21, 'Andria', 'Lussier', 'andria@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (22, 'Jessica', 'Silver', 'jess@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (23, 'Emma', 'Litt', 'emma@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (24, 'Kim', 'Dionne', 'kim@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (25, 'Alexis', 'LaPlace', 'alexis@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (26, 'allison', 'Stall', 'allison@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (27, 'Marcus', 'Liu', 'marcus@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (28, 'Joey', 'Marie', 'joey@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (29, 'Megan', 'Barr', 'megan@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (30, 'Daniella', 'Dolce', 'daniella@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (31, 'Jeff', 'Ni', 'jeff@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (32, 'Frank', 'Hartman', 'frank@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (33, 'Charlotte', 'Harris', 'charlotte@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (34, 'Alan', 'Labouseur', 'alan@example.com');
INSERT INTO public.people (pid, firstname, lastname, email) VALUES (35, 'Steve', 'Cornish', 'steve@example.com');

-- Sports
INSERT INTO public.sports (name) VALUES ('Football');
INSERT INTO public.sports (name) VALUES ('Soccer');
INSERT INTO public.sports (name) VALUES ('Volleyball');
INSERT INTO public.sports (name) VALUES ('Water Polo');
INSERT INTO public.sports (name) VALUES ('Lacrosse');

-- Positions
INSERT INTO public.positions (name) VALUES ('Lineman');
INSERT INTO public.positions (name) VALUES ('Quarterback');
INSERT INTO public.positions (name) VALUES ('Running Back');
INSERT INTO public.positions (name) VALUES ('Wide Receiver');
INSERT INTO public.positions (name) VALUES ('Defender');
INSERT INTO public.positions (name) VALUES ('Middy');
INSERT INTO public.positions (name) VALUES ('Attack');

-- Positions in reference to their sports
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Football', 'Lineman');
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Football', 'Quarterback');
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Football', 'Running Back');
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Football', 'Wide Receiver');
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Lacrosse', 'Defender');
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Lacrosse', 'Attack');
INSERT INTO public.sportpositions (sportname, positionsname) VALUES ('Lacrosse', 'Middy');

-- Timeframe for eating
INSERT INTO public.eattime (hoursbeforegame) VALUES (-2);
INSERT INTO public.eattime (hoursbeforegame) VALUES (-1);
INSERT INTO public.eattime (hoursbeforegame) VALUES (0);
INSERT INTO public.eattime (hoursbeforegame) VALUES (1);
INSERT INTO public.eattime (hoursbeforegame) VALUES (2);
INSERT INTO public.eattime (hoursbeforegame) VALUES (3);
INSERT INTO public.eattime (hoursbeforegame) VALUES (4);
INSERT INTO public.eattime (hoursbeforegame) VALUES (5);
INSERT INTO public.eattime (hoursbeforegame) VALUES (6);

-- Locations
INSERT INTO public.validzipcodes (zipcode) VALUES ('15007');
INSERT INTO public.validzipcodes (zipcode) VALUES ('15008');
INSERT INTO public.validzipcodes (zipcode) VALUES ('15009');
INSERT INTO public.validzipcodes (zipcode) VALUES ('16210');
INSERT INTO public.validzipcodes (zipcode) VALUES ('19019');

INSERT INTO public.addresses (aid, address, address2, city, state, zipcode) VALUES (2, '7 Bond Lane', null, 'Bakerstown', 'PA', '15007');
INSERT INTO public.addresses (aid, address, address2, city, state, zipcode) VALUES (3, '42 Galaxy St.', null, 'Adrian', 'PA', '16210');
INSERT INTO public.addresses (aid, address, address2, city, state, zipcode) VALUES (4, '1 Baking Avenue', null, 'Philadelphia', 'PA', '19019');

-- Kitchens
INSERT INTO public.kitchens (kid, name, aid, phone) VALUES (1, 'Primary Kitchen', 4, '255-555-1414');
INSERT INTO public.kitchens (kid, name, aid, phone) VALUES (2, 'Auxiliary Kitchen', 4, '818-555-1690');

-- Accommodations
INSERT INTO public.accommodations (name) VALUES ('Nut Free');
INSERT INTO public.accommodations (name) VALUES ('Gluten Free');
INSERT INTO public.accommodations (name) VALUES ('Vegan');
INSERT INTO public.accommodations (name) VALUES ('Vegetarian');

-- Serving Units
INSERT INTO public.servingunits (unit) VALUES ('grams');
INSERT INTO public.servingunits (unit) VALUES ('slices');
INSERT INTO public.servingunits (unit) VALUES ('ounces');
INSERT INTO public.servingunits (unit) VALUES ('fluid ounces');
INSERT INTO public.servingunits (unit) VALUES ('cups');
INSERT INTO public.servingunits (unit) VALUES ('eggs');
INSERT INTO public.servingunits (unit) VALUES ('tablespoons');
INSERT INTO public.servingunits (unit) VALUES ('breast');

-- Ingredients
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (1, 'Ham', 100, 'grams', 145, 1.5, 21, 5.5);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (2, 'Turkey', 100, 'grams', 100, 4.2, 17, 1.6);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (3, 'Red Gatorade', 20, 'fluid ounces', 125, 35, 0, 0);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (4, 'Whole Wheat Bread', 2, 'slices', 140, 13, 3, 1);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (5, 'Lettuce', 2.5, 'ounces', 5, 1, 1, 1);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (6, 'Mayonnaise', 1, 'ounces', 175, 0, 0, 19);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (7, 'Lays Classic Chips', 1, 'ounces', 185, 5, 19, 19);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (10, 'Spaghetti', 0.5, 'cups', 110, 22, 4, 0.5);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (11, 'Meat Sauce', 1, 'cups', 275, 58, 12, 2);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (12, 'Water', 8, 'ounces', 0, 0, 0, 0);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (13, 'Morrison Meatballs', 4, 'ounces', 1220, 124, 50, 61);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (14, 'Egg Yolk', 1, 'eggs', 60, 1, 7, 2);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (15, 'Olive Oil', 1, 'tablespoons', 340, 20, 15, 22);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (16, 'Walnuts', 1, 'cups', 1870, 89, 118, 102);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (17, 'Roasted Chicken Breast', 1, 'breast', 1470, 188, 185, 11);
INSERT INTO public.ingredients (iid, name, baseservingsize, baseservingunit, calories, carbgrams, proteingrams, fatgrams) VALUES (18, 'Broccoli', 100, 'grams', 34, 7, 3, 0);

-- Meals
INSERT INTO public.meals (mid, name) VALUES (1, 'Classic Turkey Sandwich');
INSERT INTO public.meals (mid, name) VALUES (3, 'Caesar Salad');
INSERT INTO public.meals (mid, name) VALUES (4, 'Chicken Dinner');
INSERT INTO public.meals (mid, name) VALUES (2, 'Classic Spaghetti');
INSERT INTO public.meals (mid, name) VALUES (5, 'Meatball Spaghetti');

-- Ingredients in Meals
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (3, 1, 1);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (4, 1, 1);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (7, 1, 1);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (12, 2, 2);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (12, 3, 2);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (14, 3, 2);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (15, 3, 3);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (16, 3, 0.25);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (12, 4, 2);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (18, 4, 2);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (10, 5, 4);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (2, 1, null);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (5, 1, null);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (17, 4, null);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (13, 5, null);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (6, 1, null);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (10, 2, null);
INSERT INTO public.ingredientsinmeals (iid, mid, numberofservings) VALUES (11, 2, null);

-- how many hours before a game you should eat a meal
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (1, 1);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (2, 1);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (3, 1);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (4, 1);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (1, 3);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (2, 3);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (3, 3);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (-2, 4);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (-1, 4);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (-2, 2);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (-1, 2);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (5, 5);
INSERT INTO public.mealtimeframes (hoursbeforegame, mid) VALUES (4, 5);

-- accommodative meals
INSERT INTO public.accommodativemeals (mid, accommodation) VALUES (1, 'Nut Free');
INSERT INTO public.accommodativemeals (mid, accommodation) VALUES (2, 'Nut Free');
INSERT INTO public.accommodativemeals (mid, accommodation) VALUES (4, 'Nut Free');
INSERT INTO public.accommodativemeals (mid, accommodation) VALUES (5, 'Nut Free');

-- Kitchen Managers
INSERT INTO public.kitchenmanagers (pid, phone) VALUES (1, '203-555-2077');
INSERT INTO public.kitchenmanagers (pid, phone) VALUES (34, '555-555-4242');
INSERT INTO public.kitchenmanagers (pid, phone) VALUES (35, '602-555-9090');

-- Managers of kitchens
INSERT INTO public.managersofkitchens (managerpid, kid) VALUES (1, 1);
INSERT INTO public.managersofkitchens (managerpid, kid) VALUES (1, 2);
INSERT INTO public.managersofkitchens (managerpid, kid) VALUES (34, 2);
INSERT INTO public.managersofkitchens (managerpid, kid) VALUES (35, 1);

-- Teams
INSERT INTO public.teams (tid, sport, name) VALUES (1, 'Football', 'Wildcats');
INSERT INTO public.teams (tid, sport, name) VALUES (2, 'Football', 'Stags');
INSERT INTO public.teams (tid, sport, name) VALUES (3, 'Lacrosse', 'Knighthawks');

-- Sign up some people
INSERT INTO public.users (pid, password) VALUES (1, 'hashedPassword');
INSERT INTO public.users (pid, password) VALUES (9, 'password');
INSERT INTO public.users (pid, password) VALUES (10, 'asdf1234');
INSERT INTO public.users (pid, password) VALUES (11, 'hunter2');
INSERT INTO public.users (pid, password) VALUES (12, 'something');
INSERT INTO public.users (pid, password) VALUES (13, '#hashed');
INSERT INTO public.users (pid, password) VALUES (14, 'pass');
INSERT INTO public.users (pid, password) VALUES (15, 'luvfootball');
INSERT INTO public.users (pid, password) VALUES (16, 'somethingsecure');
INSERT INTO public.users (pid, password) VALUES (17, 'somethingsecure');
INSERT INTO public.users (pid, password) VALUES (18, 'asdfjlk1234321');
INSERT INTO public.users (pid, password) VALUES (19, 'hashed##');
INSERT INTO public.users (pid, password) VALUES (20, 'something!!!');
INSERT INTO public.users (pid, password) VALUES (21, 'what is a password?');
INSERT INTO public.users (pid, password) VALUES (22, 'why are passwords a thing?');
INSERT INTO public.users (pid, password) VALUES (23, 'probably for security reasons');
INSERT INTO public.users (pid, password) VALUES (24, 'companionCube');
INSERT INTO public.users (pid, password) VALUES (25, 'lorem ipsum');
INSERT INTO public.users (pid, password) VALUES (26, 'I should figure out how to generate these');
INSERT INTO public.users (pid, password) VALUES (27, 'there is probably something out there');
INSERT INTO public.users (pid, password) VALUES (29, 'to do that, but here is some releif');
INSERT INTO public.users (pid, password) VALUES (30, 'from grading hopefully');
INSERT INTO public.users (pid, password) VALUES (31, 'anyway hows blockchain going?');
INSERT INTO public.users (pid, password) VALUES (32, 'its going okay for me');
INSERT INTO public.users (pid, password) VALUES (33, 'lots of boilerplate');
INSERT INTO public.users (pid, password) VALUES (34, 'alpaca');
INSERT INTO public.users (pid, password) VALUES (35, 'password1234');
INSERT INTO public.users (pid, password) VALUES (28, 'somepassword1234');

-- Coaches
INSERT INTO public.coaches (pid) VALUES (1);
INSERT INTO public.coaches (pid) VALUES (34);

-- Team Staff
INSERT INTO public.teamstaff (coachpid, tid) VALUES (1, 1);
INSERT INTO public.teamstaff (coachpid, tid) VALUES (34, 3);

-- Athletes
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (9, '1998-12-01', 70, 200, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (10, '1998-12-17', 75, 190, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (11, '1998-07-07', 68, 150, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (12, '1998-11-18', 70, 200, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (13, '1996-03-11', 71, 170, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (14, '1994-03-22', 67, 150, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (15, '1998-08-04', 69, 156, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (16, '1998-12-24', 66, 153, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (17, '1998-03-16', 62, 135, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (18, '1998-12-21', 70, 160, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (19, '1997-05-24', 75, 210, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (20, '1998-05-31', 77, 200, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (21, '1996-03-13', 75, 240, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (22, '1997-01-03', 67, 140, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (23, '1996-04-16', 66, 155, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (24, '1996-03-03', 66, 153, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (25, '1998-12-17', 68, 147, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (26, '1995-09-16', 63, 136, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (28, '1996-02-14', 63, 140, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (29, '1997-11-03', 64, 133, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (30, '1997-04-01', 67, 146, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (31, '1997-12-25', 66, 158, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (32, '1998-10-31', 69, 170, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (33, '1996-08-19', 60, 191, 'female');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (34, '1998-07-13', 62, 122, 'male');
INSERT INTO public.athletes (pid, birthdate, heightinches, weightpounds, gender) VALUES (35, '1994-07-15', 60, 134, 'male');

-- Put athletes into teams
INSERT INTO public.roster (athletepid, tid, position) VALUES (9, 1, 'Lineman');
INSERT INTO public.roster (athletepid, tid, position) VALUES (10, 1, 'Lineman');
INSERT INTO public.roster (athletepid, tid, position) VALUES (11, 1, 'Lineman');
INSERT INTO public.roster (athletepid, tid, position) VALUES (12, 1, 'Quarterback');
INSERT INTO public.roster (athletepid, tid, position) VALUES (13, 1, 'Running Back');
INSERT INTO public.roster (athletepid, tid, position) VALUES (14, 1, 'Running Back');
INSERT INTO public.roster (athletepid, tid, position) VALUES (15, 1, 'Wide Receiver');

INSERT INTO public.roster (athletepid, tid, position) VALUES (17, 3, 'Defender');
INSERT INTO public.roster (athletepid, tid, position) VALUES (18, 3, 'Defender');
INSERT INTO public.roster (athletepid, tid, position) VALUES (19, 3, 'Attack');
INSERT INTO public.roster (athletepid, tid, position) VALUES (20, 3, 'Attack');
INSERT INTO public.roster (athletepid, tid, position) VALUES (21, 3, 'Attack');
INSERT INTO public.roster (athletepid, tid, position) VALUES (22, 3, 'Attack');
INSERT INTO public.roster (athletepid, tid, position) VALUES (23, 3, 'Middy');
INSERT INTO public.roster (athletepid, tid, position) VALUES (24, 3, 'Middy');
INSERT INTO public.roster (athletepid, tid, position) VALUES (25, 3, 'Middy');
INSERT INTO public.roster (athletepid, tid, position) VALUES (26, 3, 'Middy');

-- Coaches make orders
INSERT INTO public.orders (tid, placedbypid, placedat, stripechargeid) VALUES (1, 1, '2017-11-06 16:29:24.569000', 'fakeStripeCharge1');
INSERT INTO public.orders (tid, placedbypid, placedat, stripechargeid) VALUES (1, 1, '2017-11-06 16:40:04.324000', 'fakeStripeCharge2');
INSERT INTO public.orders (tid, placedbypid, placedat, stripechargeid) VALUES (3, 34, '2017-12-02 16:33:18.976000', 'fakeStripeCharge4');

-- Create the contacts for the deliveries
INSERT INTO public.contacts (pid, phone) VALUES (1, '205-555-5555');
INSERT INTO public.contacts (pid, phone) VALUES (34, '204-1515-2000');

-- Orders consist of many deliveries
INSERT INTO public.deliveries (did, ordertid, orderplacedbypid, orderplacedat, numgenericmeals, hoursbeforegame, contactpid, addressaid, eventTime) VALUES (1, 1, 1, '2017-11-06 16:29:24.569000', 1, 2, 1, 2, '2017-12-17 16:29:24.569000');
INSERT INTO public.deliveries (did, ordertid, orderplacedbypid, orderplacedat, numgenericmeals, hoursbeforegame, contactpid, addressaid, eventTime) VALUES (2, 1, 1, '2017-11-06 16:29:24.569000', 1, 3, 1, 2, '2017-12-19 16:29:24.569000');
INSERT INTO public.deliveries (did, ordertid, orderplacedbypid, orderplacedat, numgenericmeals, hoursbeforegame, contactpid, addressaid, eventTime) VALUES (3, 1, 1, '2017-11-06 16:40:04.324000', 2, 2, 1, 3, '2017-12-20 16:29:24.569000');
INSERT INTO public.deliveries (did, ordertid, orderplacedbypid, orderplacedat, numgenericmeals, hoursbeforegame, contactpid, addressaid, eventTime) VALUES (4, 3, 34, '2017-12-02 16:33:18.976000', 3, -2, 34, 3, '2017-12-21 16:29:24.569000');

-- Athletes select meals
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (10, 1, 2, '2017-12-03 13:51:22.715000');
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (15, 1, 1, '2017-12-03 08:53:33.599000');
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (9, 1, 1, '2017-12-03 14:53:53.809000');
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (10, 2, 3, '2017-12-03 16:55:43.052000');
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (15, 2, 1, '2017-12-03 07:55:45.899000');
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (20, 4, 2, '2017-12-03 05:57:21.781000');
INSERT INTO public.selections (athletepid, did, mid, madeat) VALUES (26, 4, 4, '2017-12-03 12:59:58.734000');

-- Athletes make selections for these deliveries
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (10, 1, 10, 2.3);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (10, 1, 11, 3.8);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (15, 1, 2, 2);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (15, 1, 5, 2.4);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (9, 1, 5, 2);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (9, 1, 2, 1.5);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (15, 2, 2, 2);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (15, 2, 5, 2.4);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (15, 2, 6, 3);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (15, 1, 6, 3);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (20, 4, 10, 3.2);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (20, 4, 11, 2.1);
INSERT INTO public.custommealingredients (selectionathletepid, selectiondid, iid, numberofservings) VALUES (26, 4, 17, 2.7);

-- Views

-- All Athletes allows programmers to avoid inner joins.
CREATE VIEW AllAthletes
AS
SELECT p.pid, p.firstName, p.lastName, p.email, a.birthdate, a.gender, a.heightInches, a.weightPounds
FROM People p
INNER JOIN Athletes a
  ON p.pid = a.pid;

SELECT * FROM AllAthletes;

-- All Coaches allow programmers to avoid inner joins.
CREATE VIEW AllCoaches
AS
SELECT p.*
FROM People p
INNER JOIN Coaches c
  ON p.pid = c.pid;

SELECT * FROM AllCoaches;

CREATE VIEW AllIngredientsOfAllMeals
AS
SELECT
  m.mid,
  m.name AS mealName,
  i.iid,
  i.name AS ingredientName,
  i.baseServingSize,
  i.baseServingUnit,
  i.calories,
  i.proteinGrams,
  i.carbGrams,
  i.fatGrams
FROM Ingredients i
INNER JOIN IngredientsInMeals iim USING (iid)
INNER JOIN Meals m USING (mid)
ORDER BY mid ASC;

SELECT * FROM AllIngredientsOfAllMeals;

SELECT *
FROM AllIngredientsOfAllMeals;

CREATE VIEW AccurateAllIngredientsOfAllMeals
AS
SELECT
  a.mid,
  a.mealName,
  a.iid,
  a.ingredientName,
  COALESCE(iim.numberOfServings * a.baseServingSize, a.baseServingSize) AS numberOfServings,
  a.baseServingUnit,
  COALESCE(iim.numberOfServings * a.calories, a.calories) AS calories,
  COALESCE(iim.numberOfServings * a.proteinGrams, a.proteinGrams) AS proteinGrams,
  COALESCE(iim.numberOfServings * a.carbGrams, a.carbGrams) AS carbGrams,
  COALESCE(iim.numberOfServings * a.fatGrams, a.fatGrams) AS fatGrams
FROM AllIngredientsOfAllMeals a
INNER JOIN IngredientsInMeals iim
ON iim.iid = a.iid AND iim.mid = a.mid
ORDER BY mid;

SELECT * FROM AccurateAllIngredientsOfAllMeals;


-- To be filled in by the custom meal ingredients servings
CREATE VIEW NullableAllIngredientsOfAllMeals
AS
SELECT
  a.mid,
  a.mealName,
  a.iid,
  a.ingredientName,
  iim.numberOfServings * a.baseServingSize AS numberOfServings,
  a.baseServingUnit,
  iim.numberOfServings * a.calories AS calories,
  iim.numberOfServings * a.proteinGrams AS proteinGrams,
  iim.numberOfServings * a.carbGrams AS carbGrams,
  iim.numberOfServings * a.fatGrams AS fatGrams
FROM AllIngredientsOfAllMeals a
INNER JOIN IngredientsInMeals iim
ON iim.iid = a.iid AND iim.mid = a.mid
ORDER BY mid;

-- Report for the nutrition statistics
CREATE VIEW BaselineMealNutrition
AS
SELECT
  mid,
  mealName,
  COUNT(iid) AS numberOfIngredients,
  SUM(calories) AS totalCalories,
  SUM(proteinGrams) AS totalProteinGrams,
  SUM(carbGrams) AS totalCarbGrams,
  SUM(fatGrams) AS totalFatGrams,
  SUM(proteinGrams + carbGrams + fatGrams) AS totalMacros
FROM AccurateAllIngredientsOfAllMeals
GROUP BY (mid, mealName);

SELECT * FROM BaselineMealNutrition;

-- Pending selections...
CREATE VIEW UndeliveredSelections
AS
SELECT
  p.firstName || ' ' || p.lastName AS athleteName,
  position,
  m.name,
  hoursBeforeGame,
  pe.firstName || ' ' || pe.lastName AS contactName,
  c.phone AS contactPhoneNumber,
  address,
  coalesce(address2, '') AS address2,
  city,
  state,
  zipcode,
  (d.eventTime - NOW()) AS countDown
FROM Selections s
INNER JOIN Deliveries d
  USING (did)
INNER JOIN People p
  ON p.pid = s.athletePid
INNER JOIN Roster r
  USING (athletePid)
INNER JOIN Addresses a
  ON a.aid = d.addressAid
INNER JOIN Meals m
  USING (mid)
INNER JOIN People pe
  ON d.contactPid = pe.pid
INNER JOIN Contacts c
  ON pe.pid = c.pid
WHERE d.eventTime > NOW();

-- Triggers

CREATE OR REPLACE FUNCTION checkRosterPosition()
  RETURNS TRIGGER AS $$
BEGIN
  IF NEW.position IN
         (SELECT positionsName
           FROM SportPositions
           WHERE sportName IN
              (SELECT sport
               FROM Teams
               WHERE tid = NEW.tid)) THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Athlete must have a position in correct sport.';

END;
$$ LANGUAGE 'plpgsql';

-- when you insert an athlete into a roster
-- the position for that athlete must be a valid
-- position for that team's sport.
CREATE TRIGGER check_roster_position
BEFORE INSERT ON Roster FOR EACH ROW
EXECUTE PROCEDURE checkRosterPosition();



-- Stored Procedures

-- Reports an athlete's average caloric consumption for all selections.
CREATE OR REPLACE FUNCTION averageCaloricConsumption(pidOfAthlete INTEGER)
  RETURNS INTEGER AS $$
DECLARE
  avg INTEGER;
BEGIN
  SELECT AVG(totalCalories)
  INTO avg
  FROM Selections
  INNER JOIN BaselineMealNutrition USING (mid)
  GROUP BY Selections.athletePid
  HAVING Selections.athletePid = pidOfAthlete;
  return avg;
END;
$$ LANGUAGE 'plpgsql';

SELECT averageCaloricConsumption(15);

-- Find the macronutrient percentage of a meal
CREATE OR REPLACE FUNCTION macronutrientPercentageOfMeal(mealId INTEGER)
  RETURNS TABLE(
    proteinPercentage DECIMAL,
    fatPercentage DECIMAL,
    carbPercentage DECIMAL
  ) AS $$
BEGIN
  RETURN QUERY SELECT
    totalProteinGrams / totalMacros * 100 AS proteinPercentage,
    totalFatGrams / totalMacros * 100 AS fatPercentage,
    totalCarbGrams / totalMacros * 100 AS carbPercentage
  FROM BaselineMealNutrition
  WHERE BaselineMealNutrition.mid = mealId;
END;
$$ LANGUAGE 'plpgsql';

SELECT * FROM macronutrientPercentageOfMeal(2);

CREATE OR REPLACE VIEW MacroPercentages
AS
SELECT
  mid,
    totalProteinGrams / totalMacros * 100 AS proteinPercentage,
    totalFatGrams / totalMacros * 100 AS fatPercentage,
    totalCarbGrams / totalMacros * 100 AS carbPercentage
FROM BaselineMealNutrition;


-- Finding the meals that fit a given ratio, to a degree of accuracy.
CREATE OR REPLACE FUNCTION findMealsForRatio(pos TEXT, sportText TEXT, hoursBefGame INTEGER, thresh DEC)
  RETURNS TABLE(
    mid INTEGER
  ) AS $$
DECLARE
  percentageRow RECORD;
BEGIN
  SELECT INTO percentageRow
    r.carbsMultiplier / (r.carbsMultiplier + r.proteinMultiplier + r.fatMultiplier) * 100 AS carbsPercentage,
    r.proteinMultiplier / (r.carbsMultiplier + r.proteinMultiplier + r.fatMultiplier) * 100 AS proteinPercentage,
    r.carbsMultiplier / (r.carbsMultiplier + r.proteinMultiplier + r.fatMultiplier) * 100 AS fatPercentage
  FROM Ratios r
  WHERE r.position = pos AND r.sport = sportText AND r.hoursBeforeGame = hoursBefGame;

  RETURN QUERY SELECT m.mid
  FROM MacroPercentages m
  WHERE ABS(percentageRow.proteinPercentage - m.proteinPercentage) < thresh
  AND ABS(percentageRow.fatPercentage - m.fatPercentage) < thresh
  AND ABS(percentageRow.carbsPercentage - m.carbPercentage) < thresh;

END;
$$ LANGUAGE 'plpgsql';

SELECT *
FROM findMealsForRatio('Lineman', 'Football', 1, 20)
INNER JOIN Meals USING (mid);

-- Roles
CREATE ROLE Admin;
CREATE ROLE Coach;
CREATE ROLE Athlete;
CREATE ROLE KitchenManager;

-- Admins have a lot of power.
GRANT ALL ON ALL TABLES IN SCHEMA public TO Admin;

-- Revoke all the powers...
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM Coach;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM Athlete;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM KitchenManager;

-- Coaches deal only with these tables
GRANT SELECT, INSERT, UPDATE ON Teams, Orders, Deliveries, Selections,
People, Users, Athletes, Coaches, Roster, Contacts
TO Coach;

-- shouldn't be able to change any of the meals.
GRANT SELECT ON Meals, IngredientsInMeals, Ingredients,
CustomMealIngredients, Accommodations, AccommodativeMeals
TO Coach;

-- Update their selections.
GRANT SELECT, UPDATE ON Selections TO Athlete;
GRANT SELECT ON Roster, Athletes, Meals, IngredientsInMeals, Ingredients,
CustomMealIngredients, Accommodations, AccommodativeMeals
TO Athlete;

-- Kitchen managers have all the power to change meal-related things.
GRANT ALL ON EatTime, MealTimeframes, Meals, Accommodations,
AccommodativeMeals, Ingredients, CustomMealIngredients, Meals,
IngredientsInMeals, Kitchens,KitchenManagers, ManagersOfKitchens
TO KitchenManager;

-- But they can only see the stuff that Athletes and Coaches can change.
GRANT SELECT ON Deliveries, Contacts, Selections, Athletes, People
TO KitchenManager;
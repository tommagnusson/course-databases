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
  email TEXT
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

-- A specific athlete on a team, and what that athlete's position is.
CREATE TABLE Roster (
  athletePid INTEGER NOT NULL REFERENCES Athletes(pid),
  tid INTEGER NOT NULL REFERENCES Teams(tid),
  position TEXT NOT NULL REFERENCES Positions(name),

  PRIMARY KEY(athletePid, tid)
);

-- END SPORTS STUFF --

-- BEGIN RANDOM STUFF

CREATE TABLE ValidZipCodes (
  zipCode TEXT NOT NULL PRIMARY KEY
);

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
-- like Gatorade, would have base serving size as 1 and the serving unit as 8oz. Bottle.
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
  stripeChargeId TEXT NOT NULL,

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
  mid INTEGER NOT NULL REFERENCES Meals(mid),
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
  numberOfServings DECIMAL NOT NULL,

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

-- BEGIN KITCHEN STUFF

CREATE TABLE KitchenManagers (
  pid INTEGER NOT NULL PRIMARY KEY REFERENCES People(pid),

  -- Nullable, a directory where we might not know the phone number of a manager
  phone TEXT
);

CREATE TABLE Kitchens (
  kid SERIAL NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  aid INTEGER NOT NULL REFERENCES Addresses(aid),
  phone TEXT NOT NULL
);

CREATE TABLE ManagersOfKitchens (
  managerPid INTEGER NOT NULL REFERENCES KitchenManagers(pid),
  kid INTEGER NOT NULL REFERENCES Kitchens(kid),

  PRIMARY KEY(managerPid, kid)
);

-- END KITCHEN STUFF

-- BEGIN MAGIC STUFF

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

-- BEGIN INSERT STATEMENTS

-- BEGIN CONSTANTS

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

-- Ingredents in Meals
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

-- Kitchen Managers
INSERT INTO public.kitchenmanagers (pid, phone) VALUES (1, '203-555-2077');
INSERT INTO public.kitchenmanagers (pid, phone) VALUES (34, '555-555-4242');
INSERT INTO public.kitchenmanagers (pid, phone) VALUES (35, '602-555-9090');

-- Kitchens
INSERT INTO public.kitchens (kid, name, aid, phone) VALUES (1, 'Primary Kitchen', 4, '255-555-1414');
INSERT INTO public.kitchens (kid, name, aid, phone) VALUES (2, 'Auxiliary Kitchen', 4, '818-555-1690');

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

-- Coaches
INSERT INTO public.coaches (pid) VALUES (1);
INSERT INTO public.coaches (pid) VALUES (34);

-- Team Staff
INSERT INTO public.teamstaff (coachpid, tid) VALUES (1, 1);
INSERT INTO public.teamstaff (coachpid, tid) VALUES (34, 3);

--
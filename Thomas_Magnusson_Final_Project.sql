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
  address2 TEXT NOT NULL,
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

  baseServingSize INT NOT NULL,
  baseServingUnit TEXT NOT NULL REFERENCES ServingUnits(unit),

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
CREATE TABLE Timeframes (
  timeframe TEXT NOT NULL PRIMARY KEY
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
  timeframe TEXT NOT NULL REFERENCES Timeframes(timeframe),
  contactPid INTEGER NOT NULL REFERENCES Contacts(pid)

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
  timeframe TEXT NOT NULL REFERENCES Timeframes(timeframe),
  mid INTEGER NOT NULL REFERENCES Meals(mid),

  PRIMARY KEY(timeframe, mid)
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

  timeframe TEXT NOT NULL REFERENCES Timeframes(timeframe),

  carbsMultiplier DECIMAL NOT NULL,
  proteinMultiplier DECIMAL NOT NULL,
  fatMultiplier DECIMAL NOT NULL,

  PRIMARY KEY(position, sport, timeframe)
);

-- ENG MAGIC STUFF
-- Thomas Magnusson
-- Database Management
-- Alan Labouseur

-- EON Database Creation Script - Movie Data

-- People Table (because people are necessary in almost everything)
-- pid --> firstName, lastName
CREATE TABLE People (
  pid SERIAL NOT NULL,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,

  PRIMARY KEY(pid)
);

-- MarriedTo Table (mapping out spouses)
-- pid1, pid2 --> [they simply relate one another as spouses]
CREATE TABLE MarriedTo(
  pid1 INTEGER NOT NULL REFERENCES People(pid),
  pid2 INTEGER NOT NULL REFERENCES People(pid),

  PRIMARY KEY(pid1, pid2)
);

-- List of constant state codes
-- code --> 
CREATE TABLE StateCodes(
  code varchar(2) NOT NULL,

  PRIMARY KEY(code)
);

-- AddressablePeople Table (people who have address data associated with them)
-- pid --> address, address2, city, state, zipCode
CREATE TABLE AddressablePeople (
  pid INTEGER NOT NULL REFERENCES People(pid),
  address TEXT NOT NULL,
  address2 TEXT NOT NULL,
  city TEXT NOT NULL,
  state VARCHAR(2) NOT NULL REFERENCES StateCodes(code),
  zipCode VARCHAR(6) NOT NULL, -- 6 digit zip code

  PRIMARY KEY(pid)
);

-- Colors Table (containing both eye and hair colors, and other colors)
-- color -->
CREATE TABLE Colors(
  color TEXT NOT NULL PRIMARY KEY
);

-- HairColors (Colors reserved for hair)
-- color -->
CREATE TABLE HairColors(
  color TEXT NOT NULL PRIMARY KEY REFERENCES Colors(color)
);

-- EyeColors (Colors reserved for eyes)
-- color -->
CREATE TABLE EyeColors(
  color TEXT NOT NULL PRIMARY KEY REFERENCES Colors(color)
);

-- ScreenActorsGuildAnniversaries (An actor attends one of these once)
-- anniversary -->
CREATE TABLE ScreenActorsGuildAnniversaries(
  anniversary DATE NOT NULL PRIMARY KEY
);

-- Actors (and all the random stuff we're supposed to know about them)
-- pid --> hairColor, favoriteColor, eyeColor, weightUSPounds, heightInches, guildAnniversary
CREATE TABLE Actors(
  pid INTEGER NOT NULL REFERENCES AddressablePeople(pid), -- actors have addresses
  hairColor TEXT REFERENCES HairColors(color), -- alternative to check constraint
  favoriteColor TEXT REFERENCES Colors(color), -- alternative to check constraint
  eyeColor TEXT REFERENCES EyeColors(color),   -- alternative to check constraint
  weightUSPounds INTEGER,
  heightInches INTEGER,
  guildAnniversary DATE REFERENCES ScreenActorsGuildAnniversaries(anniversary),
  
  PRIMARY KEY(pid)
);

-- Movies (because we love watch people do things on the big screen)
-- mid --> yearReleased, MPAANumber, domesticBOSalesUSD, foreignBOSalesUSD, DVDSalesUSD, bluRaySalesUSD
CREATE TABLE Movies(
  mid SERIAL NOT NULL,
  yearReleased INTEGER NOT NULL,
  MPAANumber INTEGER NOT NULL UNIQUE,
  domesticBOSalesUSD MONEY,
  foreignBOSalesUSD MONEY,
  DVDSalesUSD MONEY,
  bluRaySalesUSD MONEY,

  PRIMARY KEY(mid)
);

-- ActedIn (Relating movies and actors in those movies)
-- (actorId, mId) -->
CREATE TABLE ActedIn(
  actorId INTEGER NOT NULL REFERENCES Actors(pid),
  mId INTEGER NOT NULL REFERENCES Movies(mid),

  PRIMARY KEY(actorId, mId)
);

-- LensMakers (the people who make lenses I suppose?)
-- lmId --> name
CREATE TABLE LensMakers(
  lmId SERIAL NOT NULL,
  name TEXT NOT NULL,

  PRIMARY KEY(lmId)
);

-- DirectorsGuildAnniversaries (Directors attend these once)
-- anniversary -->
CREATE TABLE DirectorsGuildAnniversaries(
  anniversary DATE NOT NULL PRIMARY KEY
);

-- Directors (How would we make movies without them?)
-- pid --> favoriteLensMaker, guildAnniversary
CREATE TABLE Directors(
  pid INTEGER REFERENCES AddressablePeople(pid),
  favoriteLensMaker INTEGER REFERENCES LensMakers(lmId),
  guildAnniversary DATE REFERENCES DirectorsGuildAnniversaries(anniversary),

  PRIMARY KEY(pid)
);

-- Film Schools (Because Directors have to learn somewhere)
-- fsId --> name
CREATE TABLE FilmSchools(
  fsId SERIAL NOT NULL,
  name TEXT NOT NULL,

  PRIMARY KEY(fsID)
);

-- DirectorFilmSchools (where each director went for school, maybe more than one school)
-- Assumes directors can only attend a given film school once
-- directorId, fsId --> [relates directors who attended film schools]
CREATE TABLE DirectorFilmSchools(
  directorId INTEGER NOT NULL REFERENCES Directors(pid),
  fsId INTEGER NOT NULL REFERENCES FilmSchools(fsId),

  PRIMARY KEY(directorId, fsId)
);

-- MovieDirectors (movies that directors have directed)
-- mId, directorId --> [relates directors and the movies they directed]
CREATE TABLE MovieDirectors(
  mId INTEGER NOT NULL REFERENCES Movies(mId),
  directorId INTEGER NOT NULL REFERENCES Directors(pid),

  PRIMARY KEY(mId, directorId)
);

-- Write a query to show all the directors wtih whom actor "Roger Moore" has worked.

-- Get the directors for the movies in...
SELECT md.directorId, p.firstName, p.lastName
FROM MovieDirectors md
INNER JOIN People p
ON md.directorId = p.pid
WHERE mId in (
  -- the list of movies starring...
  SELECT mId
  FROM ActedIn
  WHERE actorId in (
    -- Roger Moore
    SELECT a.pid
    FROM People p
    INNER JOIN Actors a
    ON p.pid = a.pid
    WHERE p.firstName = 'Roger' AND p.lastName = 'Moore'
  )
);





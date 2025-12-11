const prompt = require("prompt-sync")();
const fs = require("fs");
const path = require("node:path");
const process = require("node:process");
const request = require("sync-request");

let template = {
  version: 5,
  scancfg: {
    fileMode: 0,
    modelMode: 0,
    ifLeaf: false,
    filetypes: [1],
    autotags: 1,
    archives: 0,
    thumbnails: 0,
    propagation: 0,
    tags: {
      include: [],
      exclude: [],
      clear: false,
    },
    attributes: {
      include: [],
      exclude: [],
      clear: false,
    },
  },
  modelmeta: {
    name: null,
    notes: "",
    tags: [],
    cover: null,
    collections: [],
    attributes: [],
  },
};

addRaceToExclude = true;
addFranchiseToExclude = true;
addJobToExclude = true;
addGenderToExclude = true;

var data = JSON.parse(JSON.stringify(template));
var race = ["unknown"];
var franchise = ["generic"];
var job = ["unknown"];
var gender = ["unknown"];
var publisher = ["unknown"];
var argi = 4;

function processData(key, value) {
  if (
    value == "unknown" ||
    value == "generic" ||
    value == "N/A" ||
    value == ""
  ) {
    switch (key) {
      case "race":
        addRaceToExclude = false;
        break;
      case "franchise":
        addFranchiseToExclude = false;
        break;
      case "class":
        addJobToExclude = false;
        break;
      case "gender":
        addGenderToExclude = false;
        break;
    }
    return;
  }
  data.scancfg.attributes.include.push({ key: key, value: value });
  if (value.includes("/")) {
    let parentValue = path.dirname(value);
    if (parentValue.endsWith("/")) {
      parentValue = parentValue.slice(0, -1);
    }
    if (
      ["pokemon", "digimon", "duel monster"].includes(parentValue) &&
      key == "race"
    ) {
      addRaceToExclude = false;
      return;
    } else if (
      [
        "nintendo",
        "nintendo/fire emblem",
        "ark system works",
        "shin megami tensei",
        "shin megami tensei/persona",
        "fromsoftware",
        "snk",
        "nier",
        "marvel",
        "final fantasy",
      ].includes(parentValue) &&
      key == "franchise"
    ) {
      addFranchiseToExclude = false;
      return;
    } else if ([].includes(parentValue) && key == "class") {
      addClassToExclude = false;
      return;
    } else if ([].includes(parentValue) && key == "publisher") {
      addPublisherToExclude = false;
      return;
    }
    processData(key, parentValue);
  }
}

function processRace(race) {
  processData("race", race);
}

function processFranchise(franchise) {
  processData("franchise", franchise);
}
function processJob(job) {
  processData("class", job);
}
function processPublisher(publisher) {
  processData("publisher", publisher);
}
function processGender(gender) {
  processData("gender", gender);
}
function processVehicle(vehicle) {
  processData("vehicle", vehicle);
}
Object.defineProperty(String.prototype, "capitalize", {
  value: function () {
    return this.charAt(0).toUpperCase() + this.slice(1);
  },
  enumerable: false,
});

function processBulk(monster, kind) {
  let name = monster.toLowerCase();
  isRegi = name.includes("regi") ? "regi/" : "";
  let speciesMatch = name.match(/(?:[0-9]*\. )?([a-zA-Z-_.0-9]+)(?: \[.*\])?/);
  let formMatch = name.match(/.* \[(.*)\]/);
  let species = speciesMatch[1];
  let form = formMatch && formMatch[1] ? formMatch[1] : "";
  processRace(kind + "/" + isRegi + species);
  if (
    [
      "mega",
      "origin",
      "gigantamax",
      "alola",
      "galar",
      "hisui",
      "paldea",
      "cosplay",
      "cap",
      "primal",
      "crowned",
      "surfing",
      "flying",
      "terastal",
      "toy",
      "pokexel",
      "clone",
    ].includes(form)
  ) {
    processRace(kind + "/" + form.replace("forme ", "").replace(" ", ""));
  }

  data.scancfg.tags.include.push("needs work");

  excludeData();
  p = species;
  if (kind == "pokemon") {
    try {
      let pokedex = request(
        "GET",
        "https://pokeapi.co/api/v2/pokemon-species/" + species,
      );
      const dexData = JSON.parse(pokedex.getBody());
      let dexNumber = String(dexData.id).padStart(4, "0") + ". ";
      formString = form != "" ? " [" + form.capitalize() + "]" : "";
      p = dexNumber + species.capitalize() + formString;
      console.log(p);
      fs.renameSync(monster, p);
    } catch (e) {
      return;
    }
  }
  saveSingle(p);

  race = [];
  data = JSON.parse(JSON.stringify(template));
  addRaceToExclude = true;
}

function getRace() {
  var race;
  if (process.argv[argi]) {
    race = process.argv[argi].split(",");
  } else {
    race = prompt("Enter the mini races (, separated): ", "unknown", {}).split(
      ",",
    );
  }
  return race;
}
function getVehicle() {
  var vehicle;
  if (process.argv[argi]) {
    vehicle = process.argv[argi].split(",");
  } else {
    vehicle = prompt(
      "Enter the vehicle type (, separated): ",
      "unknown",
      {},
    ).split(",");
  }
  return vehicle;
}
function getJob() {
  var job;
  if (process.argv[argi]) {
    job = process.argv[argi].split(",");
  } else {
    job = prompt("Enter the class (, separated): ", "unknown", {}).split(",");
  }
  return job;
}
function getFranchise() {
  var franchise;
  if (process.argv[argi]) {
    franchise = process.argv[argi].split(",");
  } else {
    franchise = prompt(
      "Enter the franchise (, separated): ",
      "generic",
      {},
    ).split(",");
  }
  return franchise;
}
function getPublisher() {
  var publisher;
  if (process.argv[argi]) {
    publisher = process.argv[argi].split(",");
  } else {
    publisher = prompt(
      "Enter the franchise (, separated): ",
      "generic",
      {},
    ).split(",");
  }
  return publisher;
}
function getGender() {
  var gender;
  if (process.argv[argi]) {
    gender = process.argv[argi].split(",");
  } else {
    gender = prompt("Enter the gender (, separated): ", "unknown", {}).split(
      ",",
    );
  }
  if (
    gender.some(
      (g) =>
        ![
          "male",
          "female",
          "nonbinary",
          "femboy",
          "trans",
          "futanari",
          "crossdresser",
          "unknown",
        ].includes(g),
    )
  ) {
    console.log("Invalid gender");
    return getGender();
  }
  return gender;
}
function getGenre() {
  var genre;
  if (process.argv[argi]) {
    genre = process.argv[argi].split(",");
  } else {
    genre = prompt("Enter the genre (, separated): ", "unknown", {}).split(",");
  }
  if (
    genre.some(
      (g) => !["fantasy", "modern", "sci-fi", "horror", "unknown"].includes(g),
    )
  ) {
    console.log("Invalid genre");
    return getGender();
  }
  return genre;
}

function saveSingle(folder = "") {
  let dataStr = JSON.stringify(data, null, 2);
  let prefix = folder ? "./" + folder + "/" : "";
  let filePath = prefix + "./config.orynt3d";
  fs.writeFileSync(filePath, dataStr);
}

function excludeData() {
  if (addRaceToExclude && race != "unknown") {
    data.scancfg.attributes.exclude.push("race");
  }
  if (addFranchiseToExclude && franchise != "generic") {
    data.scancfg.attributes.exclude.push("franchise");
  }
  if (addJobToExclude && job != "unknown") {
    data.scancfg.attributes.exclude.push("class");
  }
  if (addGenderToExclude && gender != "unknown") {
    data.scancfg.attributes.exclude.push("gender");
  }
}

switch (process.argv[3]) {
  case "monster":
  case "familiar":
    race = getRace();
    race.forEach(processRace);
    if (process.argv[3] == "familiar") {
      job = ["Familiar"];
      job.forEach(processJob);
    }
    excludeData();
    saveSingle();
    break;
  case "vehicle":
    vehicle = getVehicle();
    vehicle.forEach(processVehicle);
    excludeData();
    saveSingle();
    break;
  case "character":
    race = getRace();
    argi++;
    job = getJob();
    argi++;
    gender = getGender();
    race.forEach(processRace);
    job.forEach(processJob);
    gender.forEach(processGender);
    excludeData();
    saveSingle();
    break;
  case "franchise":
    franchise = getFranchise();
    franchise.forEach(processFranchise);
    excludeData();
    saveSingle();
    break;
  case "publisher":
    publisher = getPublisher();
    publisher.forEach(processPublisher);
    excludeData();
    saveSingle();
    break;
  case "pokemon":
    console.log("Checking and processing all pokemon in subfolders.");
    pokemon = fs.readdirSync("./").filter((d) => fs.lstatSync(d).isDirectory());
    pokemon.forEach((p) => processBulk(p, "pokemon"));
    break;
  case "digimon":
    console.log("Checking and processing all digimon in subfolders.");
    digimon = fs.readdirSync("./").filter((d) => fs.lstatSync(d).isDirectory());
    digimon.forEach((d) => processBulk(d, "digimon"));
    break;
  case "null":
    saveSingle();
    break;
  default:
    break;
}

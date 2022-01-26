// This is a module providing JS functions that will be imported and called by
// the Obsidian Templater plugin.

// In order for this to work, it has to obey the CommonJS module specification:
//     https://flaviocopes.com/commonjs/
// with the added restriction, that there can be only one module export from any
// module, and that export must match the module (file) name.

const homedir = require('os').homedir();
const vault = "obsidian/Notes/";
const top_level = homedir + "/" + vault;
const zeroPad = (num, places) => String(num).padStart(places, '0')

// Get the date string from the filename.
// For now this is just the filename, but that might change.
function get_date_str(filename) {
    var name = filename;
    //if name.includes(' ') {
    //    name = name.split(' ')[-1];
    //}
    return name;
}

// Get the year integer from the filename.
function get_year(filename) {
    var date = get_date_str(filename);
    return parseInt(date.split('-')[0]);
}

// Get the month integer from the filename.
function get_month(filename) {
    var date = get_date_str(filename);
    return parseInt(date.split('-')[1]);
}

// Get the day of the month integer from the filename.
function get_day(filename) {
    var date = get_date_str(filename);
    return parseInt(date.split('-')[2]);
}

// Get a list of the files in the specified directory.
function get_files(dir) {
    return require('fs').readdirSync(top_level + dir).sort();
}

// Get an array of integers representing the date in the filename.
function get_date_int(name) {
    var tmp_name = name;
    if (tmp_name != null && tmp_name != '' && tmp_name != undefined) {
        if (tmp_name.indexOf(' ') >= 0) {
            tmp_name = tmp_name.substr(tmp_name.lastIndexOf(' ') + 1);
        }
    }
    console.log("note: tmp_name:", tmp_name);
    var year = get_year(tmp_name);
    console.log("note: year:", year);
    var month = get_month(tmp_name);
    console.log("note: month:", month);
    var date = get_day(tmp_name);
    console.log("note: date:", date);
    return [year, month, date];
}

// Get a new date from the specified date and an offset in days.
function get_new_date(year, month, day, offset) {
    var date = new Date(year, month, day);
    console.log("note: date:", date);
    date.setDate(date.getDate() + offset);
    console.log("note: date*:", date);
    var new_year = date.getFullYear();
    var new_month = date.getMonth();
    var new_date = date.getDate();
    console.log("note: new:", new_year, new_month, new_date);
    return [new_year, new_month, new_date];
}

// Make a new date string from the specified date integers.
function make_new_date_str(year, month, day) {
    var year_str = zeroPad(year, 4);
    var month_str = zeroPad(month, 2);
    var day_str = zeroPad(day, 2);
    var date_str = `${year_str}-${month_str}-${day_str}`;
    return date_str;
}

function note(type, tp) {
    console.log("");
    console.log("");
    var dir = tp.file.folder(relative=true);
    console.log("note: dir:", dir);
    var name = tp.file.title;
    console.log("note: name:", name);
    // var files = require('fs').readdirSync(top_level + dir);
    // console.log("note: files:", files);
    var [year, month, day] = get_date_int(name);
    if (type == "prev") {
        var note = tp.date.yesterday();
    } else if (type == "next") {
        var note = tp.date.tomorrow();
    } else if (type == "prev_week") {
        var note = "Weekly " + tp.date.now("YYYY-MM-DD", -7);
    } else if (type == "next_week") {
        var note = "Weekly " + tp.date.now("YYYY-MM-DD", 7);
    } else {
        console.error("ERROR: Type must be \"prev\" or \"next\"!");
    }
    console.log("note: note:", note);
    console.log("");
    console.log("");
    return note;
}

module.exports = note;

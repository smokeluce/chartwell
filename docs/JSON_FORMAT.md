# Records JSON format

Chartwell reads one JSON file. See `sample.json` in this folder for a complete example (fake data).

## Top level

    patient    string   Name printed on the form (optional; can be overridden in the app)
    year       number   Optional, informational
    encounters array    Required. One object per visit

## Each encounter

    visit_id   string   Optional identifier, shown in search only
    date       string   Required, format yyyy-MM-dd (used for sorting and display)
    facility   string   Facility, clinic or department name. Visits with the same facility are grouped under one block on the form
    location   string   City/state, informational
    doctor     string   Provider name(s)
    address    string   Optional. Can be left empty; addresses typed into the app are saved on your Mac and take priority
    reason     string   Brief reason for the visit

Any missing field is treated as an empty string. Unknown fields are ignored.

## Privacy

Real records files should never be committed. The repo's .gitignore excludes private/, *Medical*.json and *Encounters*.json.

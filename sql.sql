UPDATE assistant_configuration
SET path_finder_json = ' {
  "metadata": {
    "source_xml": "xml.xml",
    "total_nodes": 56,
    "root_nodes": 32,
    "total_connections": 28,
    "node_types": {
      "Unknown": 2,
      "Start": 1,
      "Navigation": 15,
      "Normal": 1,
      "DTMF": 21,
      "URL": 1,
      "GenericAPIActionHandler": 2,
      "Dialout": 1,
      "Check": 6,
      "Wait": 1,
      "Exit": 2,
      "Processing": 2,
      "Patch": 1
    }
  },
  "nodes": [
    {
      "id": "0",
      "type": "Unknown",
      "value": "",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "1",
      "type": "Unknown",
      "value": "",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "2",
      "type": "Start",
      "value": "",
      "children": [
        "3"
      ],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "3",
      "type": "Navigation",
      "value": "preferred language",
      "children": [
        "4"
      ],
      "parent": "2",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "4",
      "type": "Navigation",
      "value": "promotional annoucement",
      "children": [
        "56"
      ],
      "parent": "3",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "5",
      "type": "Navigation",
      "value": "greetings script",
      "children": [
        "9"
      ],
      "parent": "56",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "6",
      "type": "Normal",
      "value": "",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "7",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "8",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "9",
      "type": "Navigation",
      "value": "mainmenu",
      "children": [
        "10",
        "35"
      ],
      "parent": "8",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "10",
      "type": "Navigation",
      "value": "databundles",
      "children": [
        "11"
      ],
      "parent": "9",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "11",
      "type": "Navigation",
      "value": "submenu1(informationandactivation)",
      "children": [
        "53"
      ],
      "parent": "12",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "12",
      "type": "DTMF",
      "value": "1",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "14",
      "type": "DTMF",
      "value": "#",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "16",
      "type": "DTMF",
      "value": "#",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "17",
      "type": "Navigation",
      "value": "500mb",
      "children": [
        "33"
      ],
      "parent": "53",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "18",
      "type": "Navigation",
      "value": "300mb",
      "children": [
        "34"
      ],
      "parent": "53",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "19",
      "type": "DTMF",
      "value": "2",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "20",
      "type": "DTMF",
      "value": "2",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "21",
      "type": "DTMF",
      "value": "1",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "22",
      "type": "DTMF",
      "value": "1",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "25",
      "type": "DTMF",
      "value": "1",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "26",
      "type": "URL",
      "value": "",
      "children": [],
      "parent": "28",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "27",
      "type": "DTMF",
      "value": "*",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "28",
      "type": "Navigation",
      "value": "10gb",
      "children": [
        "26",
        "28"
      ],
      "parent": "28",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "29",
      "type": "Navigation",
      "value": "3gb",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "30",
      "type": "DTMF",
      "value": "2",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "31",
      "type": "Navigation",
      "value": "successfulldeactiviation",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "32",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "33",
      "type": "GenericAPIActionHandler",
      "value": "activated2",
      "children": [
        "44",
        "45"
      ],
      "parent": "17",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "34",
      "type": "GenericAPIActionHandler",
      "value": "activated2",
      "children": [
        "44",
        "45"
      ],
      "parent": "18",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "35",
      "type": "Navigation",
      "value": "further assistnat",
      "children": [
        "37"
      ],
      "parent": "9",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "36",
      "type": "DTMF",
      "value": "8",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "37",
      "type": "Dialout",
      "value": "",
      "children": [
        "58",
        "41"
      ],
      "parent": "35",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "38",
      "type": "DTMF",
      "value": "9",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "39",
      "type": "Check",
      "value": "success",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "40",
      "type": "Wait",
      "value": "",
      "children": [
        "41"
      ],
      "parent": "58",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "41",
      "type": "Exit",
      "value": "",
      "children": [],
      "parent": "37",
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "42",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "43",
      "type": "Check",
      "value": "failure",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "44",
      "type": "Navigation",
      "value": "successub",
      "children": [
        "50"
      ],
      "parent": "33",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "45",
      "type": "Navigation",
      "value": "",
      "children": [
        "50"
      ],
      "parent": "33",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "46",
      "type": "Check",
      "value": "success",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "47",
      "type": "Check",
      "value": "failure",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "48",
      "type": "Check",
      "value": "success",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "49",
      "type": "Check",
      "value": "failure",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "50",
      "type": "Exit",
      "value": "",
      "children": [],
      "parent": "44",
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "51",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "52",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "53",
      "type": "Navigation",
      "value": "dailymenu",
      "children": [
        "18",
        "17"
      ],
      "parent": "11",
      "isSkippable": false,
      "land_before": 0
    },
    {
      "id": "54",
      "type": "DTMF",
      "value": "1",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "55",
      "type": "Processing",
      "value": "",
      "children": [],
      "parent": null,
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "56",
      "type": "Processing",
      "value": "setsmartivrenabledflag",
      "children": [
        "5"
      ],
      "parent": "4",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "57",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    },
    {
      "id": "58",
      "type": "Patch",
      "value": "",
      "children": [
        "40"
      ],
      "parent": "37",
      "isSkippable": false,
      "land_before": 1
    },
    {
      "id": "59",
      "type": "DTMF",
      "value": "any",
      "children": [],
      "parent": null,
      "isSkippable": true,
      "land_before": 1
    }
  ]
}
'
WHERE assistant_id = 1;



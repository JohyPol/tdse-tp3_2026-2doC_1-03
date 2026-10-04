{
  "graph": {
    "cells": [
      {
        "position": {
          "x": -117,
          "y": -59.5
        },
        "size": {
          "height": 10,
          "width": 10
        },
        "type": "Statechart",
        "id": "e231e707-a282-46eb-b836-0e0cdfcbdfba",
        "attrs": {
          "name": {
            "text": "task_display Export"
          },
          "specification": {
            "text": "interface:\n    // Evento periódico generado por el ejecutor cíclico (cada 1 ms)\n    in event evTick\n\n    // Punteros / Índices o funciones en C para gestionar el buffer circular\n    operation isBufferEmpty() : boolean\n    operation getNextChar() : integer\n    operation displayDataWrite(data : integer) : void"
          }
        },
        "z": 1
      },
      {
        "position": {
          "x": -740,
          "y": -1600
        },
        "size": {
          "height": 60,
          "width": 60
        },
        "type": "State",
        "attrs": {
          "name": {
            "text": "IDLE",
            "fontSize": 11
          }
        },
        "id": "77b738eb-5aa7-43fa-aed4-106595811bf5",
        "z": 4
      },
      {
        "position": {
          "x": -716,
          "y": -1657
        },
        "size": {
          "height": 15,
          "width": 15
        },
        "type": "Entry",
        "entryKind": "Initial",
        "attrs": {},
        "id": "cecd6a6f-1ec3-4dbb-a7b7-46bdcaba8a98",
        "embeds": [
          "dbdde81d-599c-4776-9437-98ca9c8a70f0"
        ],
        "z": 398
      },
      {
        "type": "NodeLabel",
        "label": true,
        "size": {
          "width": 15,
          "height": 15
        },
        "position": {
          "x": -716,
          "y": -1642
        },
        "attrs": {
          "label": {
            "refX": "50%",
            "textAnchor": "middle",
            "refY": "50%",
            "textVerticalAnchor": "middle"
          }
        },
        "id": "dbdde81d-599c-4776-9437-98ca9c8a70f0",
        "parent": "cecd6a6f-1ec3-4dbb-a7b7-46bdcaba8a98",
        "z": 399
      },
      {
        "type": "Transition",
        "attrs": {},
        "source": {
          "id": "cecd6a6f-1ec3-4dbb-a7b7-46bdcaba8a98"
        },
        "target": {
          "id": "77b738eb-5aa7-43fa-aed4-106595811bf5"
        },
        "connector": {
          "name": "rounded"
        },
        "labels": [
          {
            "attrs": {},
            "position": {}
          },
          {
            "attrs": {
              "label": {
                "text": "1"
              }
            }
          },
          {
            "attrs": {}
          },
          {
            "attrs": {}
          }
        ],
        "router": {
          "name": "orthogonal",
          "args": {
            "padding": 8
          }
        },
        "id": "c3d9c4c3-7d3c-47d1-8dd8-fa6f6ff51736",
        "z": 400
      },
      {
        "position": {
          "x": -717.5,
          "y": -1464
        },
        "size": {
          "width": 15,
          "height": 15
        },
        "type": "Choice",
        "attrs": {},
        "id": "c9ec8221-1699-447f-94aa-8f36abcefe97",
        "z": 402
      },
      {
        "type": "Transition",
        "attrs": {},
        "source": {
          "id": "77b738eb-5aa7-43fa-aed4-106595811bf5"
        },
        "target": {
          "id": "c9ec8221-1699-447f-94aa-8f36abcefe97"
        },
        "connector": {
          "name": "rounded"
        },
        "labels": [
          {
            "attrs": {
              "text": {
                "text": "evTick"
              }
            },
            "position": {
              "distance": 0.4868421052631579,
              "offset": -23,
              "angle": 0
            }
          },
          {
            "attrs": {
              "label": {
                "text": "1"
              }
            }
          },
          {
            "attrs": {}
          },
          {
            "attrs": {}
          }
        ],
        "id": "cf4e9043-b620-45f2-a135-6581c7fdb33f",
        "z": 403,
        "router": {
          "name": "orthogonal"
        },
        "vertices": []
      },
      {
        "position": {
          "x": -566,
          "y": -1488
        },
        "size": {
          "width": 261,
          "height": 60
        },
        "type": "State",
        "attrs": {
          "name": {
            "text": "WRITE_SINGLE_CHARACTER",
            "fontSize": 11
          },
          "specification": {
            "text": "entry / displayDataWrite(getNextChar())"
          }
        },
        "id": "d1482c8e-44b1-4b61-bedb-0acf4e068502",
        "z": 408
      },
      {
        "type": "Transition",
        "attrs": {},
        "source": {
          "id": "c9ec8221-1699-447f-94aa-8f36abcefe97"
        },
        "target": {
          "id": "77b738eb-5aa7-43fa-aed4-106595811bf5",
          "anchor": {
            "name": "topLeft",
            "args": {
              "dx": "6.667%",
              "dy": "51.667%",
              "rotate": true
            }
          },
          "priority": true
        },
        "connector": {
          "name": "rounded"
        },
        "labels": [
          {
            "attrs": {
              "text": {
                "text": "[isBufferEmpty()]"
              }
            },
            "position": {
              "distance": 0.2212288912953713,
              "offset": 10.161085944824867,
              "angle": 0
            }
          },
          {
            "attrs": {
              "label": {
                "text": "2"
              }
            }
          },
          {
            "attrs": {}
          },
          {
            "attrs": {}
          }
        ],
        "id": "51cfd02a-2acd-43b4-8e07-7561521ecab9",
        "z": 410,
        "router": {
          "name": "orthogonal"
        },
        "vertices": [
          {
            "x": -866,
            "y": -1456.47
          }
        ]
      },
      {
        "type": "Transition",
        "attrs": {},
        "source": {
          "id": "c9ec8221-1699-447f-94aa-8f36abcefe97"
        },
        "target": {
          "id": "d1482c8e-44b1-4b61-bedb-0acf4e068502",
          "anchor": {
            "name": "topLeft",
            "args": {
              "dx": "0%",
              "dy": "51.667%",
              "rotate": true
            }
          },
          "priority": true
        },
        "connector": {
          "name": "rounded"
        },
        "labels": [
          {
            "attrs": {},
            "position": {}
          },
          {
            "attrs": {
              "label": {
                "text": "2"
              }
            }
          },
          {
            "attrs": {}
          },
          {
            "attrs": {}
          }
        ],
        "id": "415315ff-8659-42dc-8ca6-ab76955e2ee9",
        "z": 412,
        "router": {
          "name": "orthogonal"
        },
        "vertices": []
      },
      {
        "type": "Transition",
        "attrs": {},
        "source": {
          "id": "d1482c8e-44b1-4b61-bedb-0acf4e068502"
        },
        "target": {
          "id": "77b738eb-5aa7-43fa-aed4-106595811bf5",
          "anchor": {
            "name": "topLeft",
            "args": {
              "dx": "98.333%",
              "dy": "56.667%",
              "rotate": true
            }
          },
          "priority": true
        },
        "connector": {
          "name": "rounded"
        },
        "labels": [
          {
            "attrs": {},
            "position": {}
          },
          {
            "attrs": {
              "label": {
                "text": "1"
              }
            }
          },
          {
            "attrs": {}
          },
          {
            "attrs": {}
          }
        ],
        "id": "25b6206f-236a-4b0d-ad22-7f85702098e2",
        "z": 413,
        "router": {
          "name": "orthogonal"
        },
        "vertices": [
          {
            "x": -456,
            "y": -1566
          }
        ]
      }
    ]
  },
  "genModel": {
    "generator": {
      "type": "create::c",
      "features": {
        "Outlet": {
          "targetProject": "",
          "targetFolder": "",
          "libraryTargetFolder": "",
          "skipLibraryFiles": "",
          "apiTargetFolder": ""
        },
        "LicenseHeader": {
          "licenseText": ""
        },
        "FunctionInlining": {
          "inlineReactions": false,
          "inlineEntryActions": false,
          "inlineExitActions": false,
          "inlineEnterSequences": false,
          "inlineExitSequences": false,
          "inlineChoices": false,
          "inlineEnterRegion": false,
          "inlineExitRegion": false,
          "inlineEntries": false
        },
        "OutEventAPI": {
          "observables": false,
          "getters": false
        },
        "IdentifierSettings": {
          "moduleName": "TaskDisplay",
          "statemachinePrefix": "taskDisplay",
          "separator": "_",
          "headerFilenameExtension": "h",
          "sourceFilenameExtension": "c"
        },
        "Tracing": {
          "enterState": false,
          "exitState": false,
          "generic": false
        },
        "Includes": {
          "useRelativePaths": false,
          "generateAllSpecifiedIncludes": false
        },
        "GeneratorOptions": {
          "userAllocatedQueue": false,
          "metaSource": false
        },
        "GeneralFeatures": {
          "timerService": false,
          "timerServiceTimeType": ""
        },
        "Debug": {
          "dumpSexec": false
        }
      }
    }
  }
}
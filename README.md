# Fileaway

## Configuration

The configuration file should be located in `~/Library/Mobile Documents/iCloud~is~workflow~my~workflows/Documents` and follow the format:

```json
{
    "Apple Developer Program Invoice": {
        "variables": [
            {"name": "Date", "type": "string"}
        ],
        "destination": [
            {"type": "text", "value": "InSeven Limited/Receipts/"},
            {"type": "variable", "value": "Date"},
            {"type": "text", "value": " Apple Distribution International Apple Developer Program Invoice"}
        ]
    },
    "test all": {
        "variables": [
            {"name": "AYearMonth", "type": "year-month"},
            {"name": "ADate", "type": "date"},
            {"name": "AString", "type": "string"}
            ],
        "destination": [
            {"type": "text", "value": "all tests/"},
            {"type": "variable", "value": "AYearMonth"},
            {"type": "variable", "value": "ADate"},
            {"type": "variable", "value": "AString"},
            {"type": "text", "value": "testing all"}
        ]
    },
    ...
}
```

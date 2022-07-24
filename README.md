## Dependant Picklist in a Table.

This poc code effectively displays dependant picklist along with a control picklist in a table using LWC. This should be used as a sample code, not plug & play solution.

## How to use

- **tableComponent** : 
    Table component to build the html table which will store the actual data set
    This component invokes the child tableRow component to represent each row 
    in a table with dynamic picklists
- **tableRow** : 
    tablerow component represents a row in a table with 2 comboboxes
    which are dependant in nature. example - Country-> State
    This component is independant of the object & field api names to be used.


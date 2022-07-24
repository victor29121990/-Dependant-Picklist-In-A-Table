import { LightningElement, wire } from 'lwc';
import fetchPicklistOptions from '@salesforce/apex/DynamicPicklistController.fetchPicklistOptions';
import fetchAccounts from '@salesforce/apex/DynamicPicklistController.fetchAccounts';
import saveAccounts from '@salesforce/apex/DynamicPicklistController.saveAccounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
/**
 * Row class being defined with prototype
 * Prototype contains getters to fetch 
 * the dependant picklist options based on control value selection
 *  
 */
function Row(record, controlValue, dependValue, index)
{
    this.record = record;
    this.controlValue = controlValue;
    this.dependValue = dependValue;
    this.Id = record.Id;
    this.index = index;
}
Row.prototype = {
    get dependOptions()
    {
        return this.mapOfCountryToState[this.controlValue].map(item=>{
            return {label:item, value:item};
        });
    },
    get activeControlOptions()
    {
        let options = this.controlOptions.map(item => {
            if(item.active)
            {
                return { label: item.label, value: item.value }
            }
        });
        return options;
    }
}
export default class TableComponent extends LightningElement {

    mapOfCountryToState;
    controlOptions;
    accountList;
    
    loaded = false;
    //get the picklist dependency in a map
    @wire(fetchPicklistOptions, { 'objectName': 'Account', 'controlFieldName': 'Country__c', 'dependFieldName': 'State__c' })
    processResult({ error, data }) {
        if (data) {
            let resultVar = JSON.parse(data);
            console.log(resultVar);
            if (resultVar.isSuccess) {
                if (resultVar.returnValue) {
                    //this.mapOfCountryToState = resultVar.returnValue.optionsMap;
                    //this.controlOptions = resultVar.returnValue.controlOptions;
                    Row.prototype.mapOfCountryToState = resultVar.returnValue.dependOptionsMap;
                    Row.prototype.controlOptions = resultVar.returnValue.controlOptions;
                    this.loaded = true;
                }
            }
        }
        else if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        //fetch records to edit
        fetchAccounts()
            .then(result => {
                let resultVar = JSON.parse(result);
                if (resultVar.isSuccess) {
                    this.accountList = resultVar.returnValue.accountList.map((item, index)=>{
                        let r = new Row(item, item.Country__c, item.State__c, index);
                        return r;
                    });
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    //handles the rowvaluechanged event fired
    //from the tablerow component when any picklist value changes
    handleRowValueChanged(e)
    {
        let index = e.detail.row.index;
        this.accountList[index].controlValue = e.detail.row.controlValue;
        this.accountList[index].dependValue = e.detail.row.dependValue;
    }
    //sample save method to save the records. not very optimized for the poc.
    handleSave()
    {
        console.log(JSON.stringify(this.accountList));
        let records = this.accountList.map(item=>{
            item.record.Country__c = item.controlValue;
            item.record.State__c = item.dependValue;
            return item.record;
        });

        saveAccounts({accounts:JSON.stringify(records)})
        .then(result=>{
            let resultVar = JSON.parse(result);
            if(resultVar.isSuccess)
            {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: resultVar.successMsg,
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }
            else{
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: resultVar.errorMsgs,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }
        })
        .catch(error=>{
            const event = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        });
    }
    
}

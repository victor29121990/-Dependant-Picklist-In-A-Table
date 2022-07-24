import { api, LightningElement, track } from 'lwc';

export default class TableRow extends LightningElement {

    //local variable
    __row;
    //api to set the variable from parent, in order to make it mutable
    @api
    get row() {
        return this.__row;
    }
    set row(val) {
        this.__row = val;
    }

    controlSelectedValue;
    dependSelectedValue;

    //handles the control picklist change
    //set the controlValue of object which re-evaluates the dependOptions getter
    //let the parent know of the change
    handleControlChange(e) {
        let controlSelectedValue = e.detail.value;
        console.log('controlSelectedValue' + controlSelectedValue);
        this.__row.controlValue = controlSelectedValue;
        this.__row = this.shallowClone(this.__row);
        let evt = new CustomEvent('rowvaluechanged', {
            detail: {
                row: this.__row
            }
        });
        this.dispatchEvent(evt);
    }

    //handles the depend picklist value change
    //set the dependvalue
    //let the parent know about the change
    handleDependChange(e)
    {
        let dependSelectedValue = e.detail.value;
        console.log('dependSelectedValue' + dependSelectedValue);
        this.__row.dependValue = dependSelectedValue;
        let evt = new CustomEvent('rowvaluechanged', {
            detail: {
                row: this.__row
            }
        });
        this.dispatchEvent(evt);
    }

    //utility method to clone the object when control picklist value changes
    // inorder to reflect the updates dependant picklist option reflect in UI
    shallowClone(obj) {
        return Object.create(
            Object.getPrototypeOf(obj),
            Object.getOwnPropertyDescriptors(obj)
        );
    }
}

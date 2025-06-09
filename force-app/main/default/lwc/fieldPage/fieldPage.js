import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import createPicklist from '@salesforce/apex/MySQLObjectListController.createPicklist';
import getPicklist from '@salesforce/apex/MySQLObjectListController.fetchWorkRowFieldPicklist';
import editPicklist from '@salesforce/apex/MySQLObjectListController.editPicklist';

export default class FieldPage extends NavigationMixin(LightningElement) {
    label;
    recordId;
    objName;
    isModalOpen = false;
    modalType;
    labeledName = '';
    pickApiName = '';
    fledType;
    picklistValues = [];
    picklistname;
    picklistId;
    @track isLoading = true;
    @track pickListSection = false; 
    textLength;
    apiName;
    @track isEditingField = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        //this.isLoading = false;
        if (currentPageReference) {
            this.recordId = currentPageReference.state.c__recordId;
            this.label = currentPageReference.state.c__label;
            this.fledType = currentPageReference.state.c__fledType;
            this.objName = currentPageReference.state.c__objName;
            this.textLength = currentPageReference.state.c__textLength;
            this.apiName = currentPageReference.state.c__apiName;
        }
        this.showPickListSection();
        
    }

    openModal() {
        this.modalType = 'Add New'; 
        this.isModalOpen = true;
        this.forNew = true;
        this.forEdit = false;
        this.labeledName = '';  
        this.pickApiName = ''; 
        this.picklistname = '';
    }
    
    showPickListSection(){
        if (this.fledType === 'PICKLIST') {
            this.pickListSection = true;  // Show picklist section if PICKLIST type
        } else {
            this.pickListSection = false; // Otherwise, hide it
        }
        this.loadPicklistValues(); // Load picklist values (if any)
    }

    closeModal() {
        this.isModalOpen = false;
        this.labeledName = '';
        this.pickApiName = '';
    }

    handleEdit(event) {
        this.modalType = 'Edit';
        this.isModalOpen = true;
        this.picklistname = event.target.dataset.label;
        this.picklistId = event.target.dataset.id;
        this.pickApiName = this.picklistname.replace(/ /g, '_');

    }

    handleLabelChange(event) {
        this.labeledName = event.target.value;
        this.pickApiName = this.labeledName.replace(/ /g, '_');
    }

    saveValues() {
        console.log('Saved Value:', this.labeledName);
        console.log('Saved API Name:', this.recordId);
        this.isLoading = true;

        if (this.modalType == 'Add New') {
           // alert(this.modalType);
            // Create new picklist
            createPicklist({ labeledName: this.labeledName, recordId: this.recordId })
                .then(result => {
                    console.log('Picklist value saved successfully');
                    this.loadPicklistValues();
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Error creating object: ', error);
                });
        } else if (this.modalType == 'Edit') {
           //  alert(this.modalType);
            // Edit existing picklist
            editPicklist({ picklistname: this.labeledName, picklistId: this.picklistId })
                .then(result => {
                    console.log('Picklist value edited successfully');
                    this.loadPicklistValues();
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Error while editing picklist: ', error);
                });
        }
        
        this.closeModal();
    }

    loadPicklistValues() {
        this.isLoading = true;
        getPicklist({ fieldId: this.recordId })
            .then((data) => {
                console.log('Picklist Data received from Apex:', JSON.stringify(data, null, 2));
                this.picklistValues = data;
                this.error = undefined;
            })
            .catch((error) => {
                console.error('Error received from Apex:', error);
                this.error = error;
                this.picklistValues = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleBackClick(){
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'mySOQLPackage2G__mySQLHome'
            }
        })
    }

    editFieldModal(){
        this.isEditingField = true;
    }
    closeEidtField(){
        this.isEditingField = false;
    }
    handleEditSave(){
        this.isEditingField = false;
        const lengthInput = this.template.querySelector('[data-id="textLength"]').value;
        console.log(lengthInput);
    }
}
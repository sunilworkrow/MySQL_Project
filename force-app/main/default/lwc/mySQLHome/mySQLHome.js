import { LightningElement, wire, track } from 'lwc';
import getObjects from '@salesforce/apex/MySQLObjectListController.fetchWorkRowObjects';
import saveObject from '@salesforce/apex/MySQLObjectListController.saveObject';
import getFields from '@salesforce/apex/MySQLObjectListController.fetchWorkRowField';
import saveField from '@salesforce/apex/MySQLObjectListController.saveField';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class MySQLHome extends NavigationMixin(LightningElement) {

    @track objects = [];
    @track fields = [];
    @track error;
    @track isLoading = true;
    isModalOpen = false;
    objectName;
    labeledName = '';
    showObjSection = true;
    showFieldSection = false;
    clickedObjLabelName;
    isFieldModalOpen = false;
    labeledFieldName = '';
    clickedApiName;
    fieldName;
    fieldType;
    wiredObjectsResult;
    showInsertModal = false;
    selectedFieldsLables = [];
    selectedFieldsApi = [];
    timestamp = [];
    feldtimestamp = [];
    isLength = false;
    lengthValue = '';
    textLength;
    searchTerm = '';  
    timestamp = ''; 


    @wire(getObjects)
    wiredObjects({ error, data }) {
        if (data) {
            this.objects = data.map(obj => {
                const dateStr = obj.updated_at;
                const dateObj = new Date(dateStr.replace(" ", "T"));
                return { ...obj, timestamp: dateObj.getTime() };  
            });
            this.isLoading = false;
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching objects:', error);
            this.error = error;
            this.isLoading = false;
            this.objects = [];
        }
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    get filteredObjects() {
        if (!this.searchTerm) {
            return this.objects;
        }
        return this.objects.filter(obj =>
            obj.label.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
            obj.api_name.toLowerCase().includes(this.searchTerm.toLowerCase())
        );
    }

    get computedObjects() {
        const filtered = this.filteredObjects;
        return filtered.map((obj, index) => {
            const isLast = index === filtered.length - 1;
            return {
                ...obj,
                customStyle: isLast ? 'margin-left: 0 !important;' : ''
            };
        });
    }

    handleCreateObject() {
        this.isModalOpen = true;
    }

    closeObjModal() {
        this.isModalOpen = false;
    }

    handleLabelChange(event) {
        this.labeledName = event.target.value.trim(); 
        this.objectName = this.labeledName.toLowerCase().replace(/ /g, '_');
    }

    saveObject() {
        this.isLoading = true;
        this.isModalOpen = false;

        saveObject({ labeledName: this.labeledName, objName: this.objectName })
            .then(result => {
                console.log('Object saved successfully', result);
                return refreshApex(this.wiredObjectsResult)
                    .then(() => {
                        if (result.includes('Object created successfully')) {
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Success',
                                message: result,
                                variant: 'success',
                            }));
                        } else {
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Error',
                                message: result,
                                variant: 'error',
                            }));
                        }
                    });
            })
            .then(() => {
                console.log('Wire refreshed successfully');
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error creating object or refreshing wire: ', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'An error occurred while saving the object.',
                    variant: 'error',
                }));
                this.isLoading = false;
            });
    }

    handleLabelClick(event) {
        const label = event.target.dataset.label;
        const apiName = event.target.dataset.api_name;

        console.log('Label:', label);
        console.log('API Name:', apiName);

        this.clickedObjLabelName = label;
        this.clickedApiName = apiName;
        this.showObjSection = false;
        this.showFieldSection = true;
        this.loadFields();
    }

    get options() {
        return [
            { label: 'Select', value: '' },
            { label: 'Date', value: 'date' },
            { label: 'Date & Time', value: 'datetime' },
            { label: 'Decimal', value: 'decimal' },
            { label: 'Number', value: 'number' },
            { label: 'Picklist', value: 'picklist' },
            { label: 'Text', value: 'text' }
        ];
    }

    handleCreateNewField() {
        this.isFieldModalOpen = true;
    }
    closeFieldModal() {
        this.isFieldModalOpen = false;
        this.fieldType = '';
    }

    handleBackButton() {
        this.showFieldSection = false;
        this.showObjSection = true;
    }

    handleFeildNameChange(event) {
        this.labeledFieldName = event.target.value.trim();
        this.fieldName = this.labeledFieldName.toLowerCase().replace(/ /g, '_');
    }
    handleFieldTypeChange(event) {
        this.fieldType = event.target.value;
        switch (this.fieldType) {
            case 'text':
                this.isLength = true;
                break;
            default:
                this.isLength = false;
                break;
        }
    }
    handleLengthInput(event) {
        this.lengthValue = event.target.value;

    }
    handleSaveField() {
        this.isFieldModalOpen = false;
        console.log('this.fieldType', this.fieldType);
        console.log('this.fieldName', this.fieldName);
        console.log('this.labeledFieldName', this.labeledFieldName);
        console.log('clickedLabelName', this.clickedObjLabelName);
        console.log('Length value', this.lengthValue)
        saveField({ labeledName: this.labeledFieldName, fieldName: this.fieldName, fieldType: this.fieldType, objName: this.clickedApiName, textLength: this.lengthValue })
            .then(result => {
                console.log(result);
                if (result.includes('Field created successfully')) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: result,
                        variant: 'success',
                    }));
                } else {
                    // If result contains an error message, show error toast
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result,
                        variant: 'error',
                    }));
                }
                this.loadFields();
                this.fieldType = '';
            })
            .catch(error => {
                console.error('Error creating object: ', error);
            });
    }

    loadFields() {
        this.isLoading = true;
        getFields({ objName: this.clickedApiName })
            .then((data) => {
                //console.log('Field-Data received from Apex:', JSON.stringify(data, null, 2));
                this.fields = data;
                this.error = undefined;
                this.selectedFieldsLables = data.map(field => field.label);
                this.selectedFieldsApi = data.map(field => field.api_name);
                this.textLength = data.map(field => field.length);
                console.log('Selected Field Labels:', JSON.stringify(this.selectedFieldsLables));
                console.log('Selected Field API:', JSON.stringify(this.selectedFieldsApi));
                console.log('Selected Field Text Length:', JSON.stringify(this.textLength));

                if (data) {
                    data.forEach((flds) => {
                        const dateStr = flds.updated_at;
                        const dateflds = new Date(dateStr.replace(" ", "T"));  // Make sure it's in ISO format
                        this.feldtimestamp = dateflds.getTime(); // Get the timestamp in milliseconds

                    });
                }
            })
            .catch((error) => {
                console.error('Error received from Apex:', error);
                this.error = error;
                this.fields = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    navigateToAnotherComponent(event) {
        const label = event.target.dataset.label;
        const fieldType = event.target.dataset.fieldtype;
        const recordId = event.target.dataset.id;
        const textLength = event.target.dataset.textlength;
        const apiName = event.target.dataset.apiname;

        console.log(label, 'and', fieldType, 'id', recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'mySOQLPackage2G__fieldPage'
            },
            state: {
                c__recordId: recordId,
                c__label: label,
                c__objName: this.clickedObjLabelName,
                c__fledType: fieldType,
                c__textLength: textLength,
                c__apiName: apiName
            }
        })

    }

    handleRecordInsert() {
        //alert('HEY');
        if (this.selectedFieldsLables.length > 0) {
            //alert('HEY2');
            this.showInsertModal = true;  // Open modal if fields are loaded
        } else {
            // Optionally show an alert if no fields are loaded
            console.error('No fields available.');
        }
    }

    closeModal() {
        this.showInsertModal = false;
    }

    handleRecordListt() {
        console.log('Button value:', this.clickedApiName);
        // alert(this.clickedApiName);
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'mySOQLPackage2G__recordListPage'
            },
            state: {
                c__objApiName: this.clickedApiName,
                c__objLabelName: this.clickedObjLabelName
            }
        })
    }

    handleRecordInserted(event) {
        //alert('hello');
        this.isLoading = true;
        const { message, variant } = event.detail;
        this.isLoading = false;

        this.dispatchEvent(new ShowToastEvent({
            title: variant === 'success' ? 'Success' : 'Error',
            message: message,
            variant: variant, // 'success' or 'error'
        }));
    }


}
import { LightningElement, track } from 'lwc';
import crearTanquesDesdeCSV from '@salesforce/apex/CargaMasivaTanquesCSV.crearTanquesDesdeCSV';
import getTipos from '@salesforce/apex/CargaMasivaTanquesCSV.getTipos';
import PapaParse from '@salesforce/resourceUrl/papaparse';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TanqueUploader extends LightningElement {
    @track tipoOptions = [];
    @track tipoSeleccionado;
    @track datosPreview = [];
    papaParseInitialized = false;

    connectedCallback() {
        loadScript(this, PapaParse)
            .then(() => {
                console.log('✅ PapaParse cargado:', window.Papa);
                this.papaParseInitialized = true;
                this.cargarTiposDeTanque();
            })
            .catch(error => {
                console.error('❌ Error PapaParse:', error);
                this.showError('Error cargando PapaParse');
            });
    }

    cargarTiposDeTanque() {
        getTipos()
            .then(result => {
                this.tipoOptions = result.map(tipo => ({
                    label: tipo.Name,
                    value: tipo.Id
                }));
            })
            .catch(error => {
                this.showError('Error cargando tipos de tanque');
            });
    }

    handleTipoChange(event) {
        this.tipoSeleccionado = event.detail.value;
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        if (!file || !this.papaParseInitialized) {
            this.showError('PapaParse no está listo o no seleccionaste un archivo');
            return;
        }
    
        window.Papa.parse(file, {
            header: true,
            skipEmptyLines: true,
            complete: (results) => {
                const capacidades = results.data.map((row, i) => {
                    return {
                        Capacidad__c: row['Capacidad'],
                        key: `${i}-${row['Capacidad']}`
                    };
                }).filter(row => row.Capacidad__c);
    
                this.datosPreview = capacidades;
    
                const cantidadCandidatos = capacidades.length;
    
                crearTanquesDesdeCSV({
                    tipoTanqueId: this.tipoSeleccionado,
                    datos: capacidades
                })
                .then(() => {
                    this.showSuccess(`Intento de carga de ${cantidadCandidatos} tanques finalizado correctamente.`);
                })
                .catch(error => {
                    console.error('❌ Error en Apex:', error);
                    this.showError(error.body?.message || 'Error al cargar los tanques.');
                });
            },
            error: (err) => {
                this.showError('Error procesando el CSV');
                console.error(err);
            }
        });
    }
    get datosPreviewFormateados() {
        return this.datosPreview.map(row => ({
            key: row.key,
            texto: `Capacidad: ${row.Capacidad__c}`
        }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Éxito',
            message,
            variant: 'success'
        }));
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message,
            variant: 'error'
        }));
    }
}

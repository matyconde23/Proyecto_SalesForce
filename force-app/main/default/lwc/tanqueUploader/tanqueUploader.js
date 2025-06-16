import { LightningElement, track } from 'lwc';
import crearTanquesDesdeCSV from '@salesforce/apex/CargaMasivaTanquesCSV.crearTanquesDesdeCSV';
import obtenerTiposTanque from '@salesforce/apex/CargaMasivaTanquesCSV.obtenerTiposTanques';
import PapaParse from '@salesforce/resourceUrl/papaparse';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TanqueUploader extends LightningElement {
    @track tipoOpciones = [];
    @track tipoSeleccionado;
    @track datosPrevios = [];
    papaParseCargado = false;

    // Se ejecuta al cargar el componente
    connectedCallback() {
        loadScript(this, PapaParse)
            .then(() => {
                console.log('✅ PapaParse cargado');
                this.papaParseCargado = true;
                this.cargarTiposDeTanque();
            })
            .catch((error) => {
                console.error('❌ Error cargando PapaParse:', error);
                this.mostrarError('Error cargando PapaParse');
            });
    }

    // Llama a Apex para obtener los tipos de tanque
    cargarTiposDeTanque() {
        obtenerTiposTanque()
            .then((resultado) => {
                this.tipoOpciones = resultado.map((tipo) => ({
                    label: tipo.Name,
                    value: tipo.Id
                }));
                console.log('📄 Tipos de tanque cargados:', this.tipoOpciones);
            })
            .catch((error) => {
                console.error('❌ Error al obtener tipos:', error);
                this.mostrarError('Error cargando tipos de tanque');
            });
    }

    // Guarda el tipo de tanque seleccionado
    cambiarTipoSeleccionado(evento) {
        this.tipoSeleccionado = evento.detail.value;
        console.log('🏷 Tipo seleccionado:', this.tipoSeleccionado);
    }

    // Maneja el archivo CSV subido por el usuario
    manejarCargaDeArchivo(evento) {
        const archivo = evento.target.files[0];

        if (!archivo || !this.papaParseCargado) {
            this.mostrarError('PapaParse no está listo o no seleccionaste un archivo');
            return;
        }

        console.log('📂 Archivo seleccionado:', archivo.name);

        window.Papa.parse(archivo, {
            header: true,
            skipEmptyLines: true,
            complete: (resultado) => {
                console.log('🧾 Resultados parseados:', resultado.data);

                const filasValidas = resultado.data
                    .map((fila, i) => {
                        console.log(`🔍 Fila ${i + 1}:`, fila);
                        return {
                            Capacidad__c: fila['Capacidad'],
                            Numero_fabricacion__c: fila['Numero_fabricacion'],
                            key: `${i}-${fila['Capacidad']}-${fila['Numero_fabricacion']}`
                        };
                    })
                    .filter((fila) => fila.Capacidad__c);

                console.log('✅ Datos filtrados para Apex:', filasValidas);

                this.datosPrevios = filasValidas;
                const cantidad = filasValidas.length;

                crearTanquesDesdeCSV({
                    tipoTanqueId: this.tipoSeleccionado,
                    datos: filasValidas
                })
                    .then(() => {
                        this.mostrarExito(`Se cargaron ${cantidad} tanques correctamente.`);
                        console.log('✅ Tanques creados correctamente.');
                    })
                    .catch((error) => {
                        console.error('❌ Error en Apex:', error);
                        this.mostrarError(error.body?.message || 'Error al cargar los tanques.');
                    });
            },
            error: (error) => {
                console.error('❌ Error al parsear CSV:', error);
                this.mostrarError('Error procesando el archivo CSV');
            }
        });
    }

    // Vista previa de los datos antes de enviar
    get vistaPreviaFormateada() {
        return this.datosPrevios.map((fila) => ({
            key: fila.key,
            texto: `Capacidad: ${fila.Capacidad__c}`
        }));
    }

    // Muestra un mensaje de éxito
    mostrarExito(mensaje) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Éxito',
                message: mensaje,
                variant: 'success'
            })
        );
    }

    // Muestra un mensaje de error
    mostrarError(mensaje) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: mensaje,
                variant: 'error'
            })
        );
    }
}

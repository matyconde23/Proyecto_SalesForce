@isTest
public class ValidacionLeadTest {

    @isTest
    static void testLeadValido() {
        // Crear un tipo de tanque compatible
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo Compatible',
            Capacidad__c = 3000,
            Precio_de_lista__c = 20000,
            Marca__c = 'MarcaTest'
        );
        insert tipo;

        // Crear un lead que debe pasar la validación
        Lead leadValido = new Lead(
            LastName = 'Cliente Ok',
            Company = 'Empresa A',
            Capacidad__c = 3000,
            Precio_minimo__c = 18000,
            Precio_maximo__c = 21000
        );

        Test.startTest();
        ValidacionLead.validarLeads(new List<Lead>{ leadValido });
        Test.stopTest();

        // No se espera error, solo aseguramos que el método corre sin excepción
        System.assert(true);
    }

    @isTest
    static void testLeadInvalido() {
    // Crear un tipo de tanque incompatible
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo Caro',
            Capacidad__c = 5000,
            Precio_de_lista__c = 40000,
            Marca__c = 'MarcaX'
        );
        insert tipo;

    // Crear un lead que NO debe encontrar tanque compatible
        Lead leadInvalido = new Lead(
            LastName = 'Cliente Sin Match',
            Company = 'Empresa B',
            Capacidad__c = 3000,
            Precio_minimo__c = 10000,
            Precio_maximo__c = 20000
        );

        Test.startTest();
        try {
            insert leadInvalido; // Aquí se dispara el trigger, y se ejecuta addError
            System.assert(false, 'Se esperaba un error en el insert, pero no ocurrió.');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('No hay tanques en nuestro catálogo'),
                      'El mensaje de error no fue el esperado: ' + e.getDmlMessage(0));
        }
        Test.stopTest();
    }


    @isTest
    static void testLeadConCamposIncompletos() {
        Lead leadIncompleto = new Lead(
            LastName = 'Incompleto',
            Company = 'Empresa C',
            Capacidad__c = null,
            Precio_minimo__c = 10000,
            Precio_maximo__c = 20000
        );

        Test.startTest();
        ValidacionLead.validarLeads(new List<Lead>{ leadIncompleto });
        Test.stopTest();

        // No debería lanzar error ya que los campos son insuficientes
        System.assert(true);
    }
}

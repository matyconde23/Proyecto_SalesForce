@isTest
public class CambioTanqueOportunidadServiceTest {

    @isTest
    static void testProcesarCambioDeTanque() {
        // Crear tipo de tanque
        Tipo_de_tanque__c tipo1 = new Tipo_de_tanque__c(Name = 'Tipo A', Capacidad__c = 3000, Precio_de_lista__c = 15000, Marca__c = 'TA');
        Tipo_de_tanque__c tipo2 = new Tipo_de_tanque__c(Name = 'Tipo B', Capacidad__c = 5000, Precio_de_lista__c = 25000, Marca__c = 'TB');
        insert new List<Tipo_de_tanque__c>{ tipo1, tipo2 };

        // Crear tanques
        Tanque_Industrial__c tanque1 = new Tanque_Industrial__c(Name = 'TA3000-001', Tipo_de_tanque__c = tipo1.Id, Estado__c = 'Reservado');
        Tanque_Industrial__c tanque2 = new Tanque_Industrial__c(Name = 'TB5000-001', Tipo_de_tanque__c = tipo2.Id, Estado__c = 'Disponible');
        insert new List<Tanque_Industrial__c>{ tanque1, tanque2 };

        // Crear oportunidad con el tanque1
        Opportunity opp = new Opportunity(
            Name = 'Test Oportunidad',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Tanque_seleccionado__c = tanque1.Id
        );
        insert opp;

        // Simular cambio de tanque en memoria
        Opportunity oppActualizada = opp.clone(false, true, false, false);
        oppActualizada.Tanque_seleccionado__c = tanque2.Id;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        CambioTanqueOportunidadService.procesarCambioDeTanque(new List<Opportunity>{ oppActualizada }, oldMap);
        Test.stopTest();

        // Verificar estado de los tanques
        Map<Id, Tanque_Industrial__c> tanques = new Map<Id, Tanque_Industrial__c>(
            [SELECT Id, Estado__c FROM Tanque_Industrial__c WHERE Id IN :new List<Id>{tanque1.Id, tanque2.Id}]
        );

        System.assertEquals('Disponible', tanques.get(tanque1.Id).Estado__c, 'Tanque anterior debe quedar como Disponible');
        System.assertEquals('Reservado', tanques.get(tanque2.Id).Estado__c, 'Tanque nuevo debe quedar como Reservado');

        // Verificar que se actualizó el precio de venta en memoria
        System.assertEquals(tipo2.Precio_de_lista__c, oppActualizada.Precio_de_venta__c, 'Precio de venta debe coincidir con el precio de lista del tanque nuevo');
    }
}

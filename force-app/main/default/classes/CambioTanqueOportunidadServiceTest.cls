@isTest
public class CambioTanqueOportunidadServiceTest {

    @isTest
    static void testCambioDeTanqueActualizaEstadosYPrecio() {
        // Crear tipos de tanque
        Tipo_de_tanque__c tipoA = new Tipo_de_tanque__c(Name = 'Tipo A', Capacidad__c = 3000, Precio_de_lista__c = 15000, Marca__c = 'TA');
        Tipo_de_tanque__c tipoB = new Tipo_de_tanque__c(Name = 'Tipo B', Capacidad__c = 5000, Precio_de_lista__c = 25000, Marca__c = 'TB');
        insert new List<Tipo_de_tanque__c>{ tipoA, tipoB };

        // Crear tanques
        Tanque_Industrial__c tanqueA = new Tanque_Industrial__c(Name = 'TA3000-001', Tipo_de_tanque__c = tipoA.Id, Estado__c = 'Reservado');
        Tanque_Industrial__c tanqueB = new Tanque_Industrial__c(Name = 'TB5000-001', Tipo_de_tanque__c = tipoB.Id, Estado__c = 'Disponible');
        insert new List<Tanque_Industrial__c>{ tanqueA, tanqueB };

        // Crear oportunidad con el tanque A
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad de prueba',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(7),
            Tanque_seleccionado__c = tanqueA.Id
        );
        insert opp;

        // Simular cambio de tanque en memoria (como si fuera trigger.before update)
        Opportunity oppActualizada = opp.clone(false, true, false, false);
        oppActualizada.Id = opp.Id;
        oppActualizada.Tanque_seleccionado__c = tanqueB.Id;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        CambioTanqueOportunidadService.procesarCambioDeTanque(new List<Opportunity>{ oppActualizada }, oldMap);
        Test.stopTest();

        // Verificar estados de los tanques
        List<Tanque_Industrial__c> tanquesPost = [
            SELECT Id, Estado__c FROM Tanque_Industrial__c WHERE Id IN :new List<Id>{tanqueA.Id, tanqueB.Id}
        ];
        Map<Id, Tanque_Industrial__c> tanqueMap = new Map<Id, Tanque_Industrial__c>(tanquesPost);

        System.assertEquals('Disponible', tanqueMap.get(tanqueA.Id).Estado__c, 'El tanque anterior debe quedar como Disponible');
        System.assertEquals('Reservado', tanqueMap.get(tanqueB.Id).Estado__c, 'El nuevo tanque debe quedar como Reservado');

        // Verificar precio de venta actualizado en memoria
        System.assertEquals(tipoB.Precio_de_lista__c, oppActualizada.Precio_de_venta__c, 'Debe actualizarse el precio de venta al del nuevo tipo de tanque');
    }

}

public with sharing class CrearOportunidadAutomatica {

    /**
     * Crea o actualiza una oportunidad a partir de un Lead convertido,
     * y asigna un tanque disponible o, si no hay, genera un pedido de tanque.
     *
     * También actualiza los valores de capacidad y precio en la cuenta relacionada.
     *
     * @param leadId ID del Lead ya convertido
     * @return La oportunidad creada o actualizada
     * @throws AuraHandledException Si no se encuentra un tipo de tanque compatible
     */
    public static Opportunity crearOportunidadDesdeLead(Id leadId) {
        System.debug('🔥 INICIO: crearOportunidadDesdeLead ejecutado');

        // 🔍 Traer datos del Lead
        Lead lead = [
            SELECT Id, Capacidad__c, Precio_minimo__c, Precio_maximo__c, Company, OwnerId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        System.debug('🔍 Lead cargado: ' + lead);

        // 🔒 Validar que exista al menos un tipo de tanque con la capacidad del lead
        Boolean existeTipoConEsaCapacidad = [
            SELECT COUNT()
            FROM Tipo_de_tanque__c
            WHERE Capacidad__c = :lead.Capacidad__c
        ] > 0;

        if (!existeTipoConEsaCapacidad) {
            System.debug('❌ No existe ningún tipo de tanque con capacidad ' + lead.Capacidad__c);
            throw new AuraHandledException('No existe ningún tipo de tanque con la capacidad indicada en el Lead (' + lead.Capacidad__c + '). Verificá los datos ingresados.');
        }

        // Paso 1: Buscar tanques disponibles para la capacidad solicitada
        List<AggregateResult> disponiblesPorTipo = [
            SELECT Tipo_de_tanque__c tipoId, COUNT(Id) cantidad
            FROM Tanque_Industrial__c
            WHERE Estado__c = 'Disponible'
            AND Tipo_de_tanque__r.Capacidad__c = :lead.Capacidad__c
            GROUP BY Tipo_de_tanque__c
        ];

        Set<Id> tiposConStock = new Set<Id>();
        for (AggregateResult ar : disponiblesPorTipo) {
            tiposConStock.add((Id) ar.get('tipoId'));
        }

        List<Tipo_de_tanque__c> tiposAdecuados = new List<Tipo_de_tanque__c>();

        // Si hay tipos con stock disponibles
        if (!tiposConStock.isEmpty()) {
            tiposAdecuados = [
                SELECT Id, Capacidad__c, Precio_de_lista__c
                FROM Tipo_de_tanque__c
                WHERE Id IN :tiposConStock
                AND Precio_de_lista__c >= :lead.Precio_minimo__c
                AND Precio_de_lista__c <= :lead.Precio_maximo__c
                ORDER BY Precio_de_lista__c ASC
                LIMIT 1
            ];
        } else {
            // No hay stock → buscar el tipo más barato compatible para crear pedido
            tiposAdecuados = [
                SELECT Id, Capacidad__c, Precio_de_lista__c
                FROM Tipo_de_tanque__c
                WHERE Capacidad__c = :lead.Capacidad__c
                AND Precio_de_lista__c >= :lead.Precio_minimo__c
                AND Precio_de_lista__c <= :lead.Precio_maximo__c
                ORDER BY Precio_de_lista__c ASC
                LIMIT 1
            ];
        }

        if (tiposAdecuados.isEmpty()) {
            System.debug('❌ No se encontró tipo de tanque adecuado');
            throw new AuraHandledException('No se encontró un tipo de tanque que cumpla con los criterios del cliente.');
        }

        Tipo_de_tanque__c tipoSeleccionado = tiposAdecuados[0];
        System.debug('✅ Tipo seleccionado: ' + tipoSeleccionado);

        // Buscar tanque disponible de ese tipo (por ID directo)
        List<Tanque_Industrial__c> tanquesDisponibles = [
            SELECT Id, Estado__c, Tipo_de_tanque__c
            FROM Tanque_Industrial__c
            WHERE Tipo_de_tanque__c = :tipoSeleccionado.Id
            AND Estado__c = 'Disponible'
            LIMIT 1
        ];

        Boolean seAsignoTanque = !tanquesDisponibles.isEmpty();
        Opportunity opp;

        // Obtener oportunidad existente o crear nueva
        if (lead.ConvertedOpportunityId != null) {
            opp = [
                SELECT Id, Tanque_seleccionado__c, Pedido_Tanque__c, AccountId
                FROM Opportunity
                WHERE Id = :lead.ConvertedOpportunityId
                LIMIT 1
            ];

            // ✅ Evitar duplicación: si ya tiene tanque o pedido, no hacer nada
            if (opp.Tanque_seleccionado__c != null || opp.Pedido_Tanque__c != null) {
                System.debug('⚠️ La oportunidad ya tiene tanque o pedido asignado. Se evita duplicación.');
                return opp;
            }

        } else {
            opp = new Opportunity(
                Name = 'Venta de Tanque - ' + lead.Company,
                CloseDate = Date.today().addDays(30),
                StageName = 'Prospecting',
                OwnerId = lead.OwnerId
            );
            insert opp;
        }

        // Asignar tanque o crear pedido
        if (seAsignoTanque) {
            Tanque_Industrial__c tanqueAsignado = tanquesDisponibles[0];

            opp.Tanque_seleccionado__c = tanqueAsignado.Id;
            opp.Pedido_Tanque__c = null;

            tanqueAsignado.Estado__c = 'Reservado';
            update tanqueAsignado;

            System.debug('✅ Tanque asignado y reservado: ' + tanqueAsignado.Id);
        } else {
            // Solo crear pedido si no hay uno ya asignado
            if (opp.Pedido_Tanque__c == null) {
                Pedido_Tanque__c pedido = new Pedido_Tanque__c(
                    Estado__c = 'Pendiente',
                    Tipo_de_tanque__c = tipoSeleccionado.Id
                );
                insert pedido;

                opp.Pedido_Tanque__c = pedido.Id;
                opp.Tanque_seleccionado__c = null;

                System.debug('📋 Pedido creado y asignado: ' + pedido.Id);
            } else {
                System.debug('⚠️ La oportunidad ya tenía un pedido asignado. No se crea uno nuevo.');
            }
        }

        // Actualizar la cuenta asociada con los valores del Lead
        if (opp.AccountId != null) {
            Account cuenta = [
                SELECT Id, Capacidad__c, Precio_minimo__c, Precio_maximo__c
                FROM Account
                WHERE Id = :opp.AccountId
                LIMIT 1
            ];

            cuenta.Capacidad__c = lead.Capacidad__c;
            cuenta.Precio_minimo__c = lead.Precio_minimo__c;
            cuenta.Precio_maximo__c = lead.Precio_maximo__c;
            update cuenta;

            System.debug('✅ Cuenta actualizada correctamente con ID: ' + cuenta.Id);
        } else {
            System.debug('⚠️ La oportunidad no tiene AccountId, no se pudo actualizar la cuenta.');
        }

        // Asignar precio de venta
        opp.Precio_de_venta__c = tipoSeleccionado.Precio_de_lista__c;
        update opp;

        System.debug('📦 Oportunidad actualizada: ' + opp.Id);
        return opp;
    }
}

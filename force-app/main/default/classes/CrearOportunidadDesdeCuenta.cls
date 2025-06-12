public class CrearOportunidadDesdeCuenta {

    /**
     * Asigna automáticamente un tanque disponible a una oportunidad recién creada
     * en base a los datos de capacidad y precio de la cuenta asociada.
     * 
     * Si no hay tanques disponibles compatibles, se genera un pedido de tanque.
     *
     * @param nuevasOpps Lista de oportunidades nuevas (Trigger.new en before insert)
     */
    public static void asignarTanqueDisponible(List<Opportunity> nuevasOpps) {
        System.debug('🔁 INICIO - Asignación automática de tanque para nuevas oportunidades');

        // Recolectar los IDs de cuentas asociadas a las oportunidades
        Set<Id> cuentaIds = new Set<Id>();
        for (Opportunity opp : nuevasOpps) {
            if (opp.AccountId != null) {
                cuentaIds.add(opp.AccountId);
            }
        }

        System.debug('🔎 Cuentas a consultar: ' + cuentaIds);

        // Obtener las cuentas y sus datos necesarios
        Map<Id, Account> cuentas = new Map<Id, Account>([
            SELECT Id, Capacidad__c, Precio_minimo__c, Precio_maximo__c
            FROM Account
            WHERE Id IN :cuentaIds
        ]);

        System.debug('📦 Cuentas encontradas: ' + cuentas.keySet());

        // Listas para actualización de tanques y creación de pedidos
        List<Pedido_tanque__c> pedidosACrear = new List<Pedido_tanque__c>();
        List<Tanque_Industrial__c> tanquesAActualizar = new List<Tanque_Industrial__c>();

        // Procesar cada oportunidad
        for (Opportunity opp : nuevasOpps) {
            System.debug('\n➡️ Procesando oportunidad: ' + opp.Id);

            // Validación: la oportunidad debe tener cuenta
            if (opp.AccountId == null) {
                System.debug('⚠️ La oportunidad no tiene cuenta asociada. Se omite.');
                continue;
            }

            // Si ya tiene un tanque asignado, no hacer nada
            if (opp.Tanque_seleccionado__c != null) {
                System.debug('ℹ️ Oportunidad ya tiene un tanque asignado. Se omite.');
                continue;
            }

            // Obtener los datos de la cuenta
            Account cuenta = cuentas.get(opp.AccountId);
            if (cuenta == null) {
                System.debug('⚠️ No se encontró la cuenta asociada: ' + opp.AccountId);
                continue;
            }

            // Extraer criterios para búsqueda de tanque
            Decimal capacidadDeseada = cuenta.Capacidad__c;
            Decimal precioMin = cuenta.Precio_minimo__c;
            Decimal precioMax = cuenta.Precio_maximo__c;

            System.debug('🧾 Requisitos de cuenta: Capacidad=' + capacidadDeseada +
                         ', PrecioMin=' + precioMin + ', PrecioMax=' + precioMax);

            // Buscar tanque disponible que cumpla con los requisitos
            List<Tanque_Industrial__c> tanquesCandidatos = [
                SELECT Id, Tipo_de_tanque__c,
                       Tipo_de_tanque__r.Precio_de_lista__c,
                       Tipo_de_tanque__r.Capacidad__c
                FROM Tanque_Industrial__c
                WHERE Estado__c = 'Disponible'
                  AND Tipo_de_tanque__r.Capacidad__c = :capacidadDeseada
                  AND Tipo_de_tanque__r.Precio_de_lista__c >= :precioMin
                  AND Tipo_de_tanque__r.Precio_de_lista__c <= :precioMax
                ORDER BY Tipo_de_tanque__r.Precio_de_lista__c ASC
                LIMIT 1
            ];

            if (!tanquesCandidatos.isEmpty()) {
                // Tanque compatible encontrado
                Tanque_Industrial__c mejorOpcion = tanquesCandidatos[0];
                Decimal cap = mejorOpcion.Tipo_de_tanque__r.Capacidad__c;
                Decimal precio = mejorOpcion.Tipo_de_tanque__r.Precio_de_lista__c;

                System.debug('🎯 Tanque encontrado: ' + mejorOpcion.Id);
                System.debug('🔍 Comparación: capacidad tanque = ' + cap + ' == ' + capacidadDeseada);
                System.debug('🔍 Comparación: precio tanque = ' + precio +
                             ' dentro de rango [' + precioMin + ', ' + precioMax + ']');

                // Asignar tanque a la oportunidad
                opp.Tanque_seleccionado__c = mejorOpcion.Id;

                // Cambiar estado del tanque a reservado
                mejorOpcion.Estado__c = 'Reservado';
                tanquesAActualizar.add(mejorOpcion);
            } else {
                // No hay tanque disponible → generar pedido
                System.debug('⚠️ No se encontró tanque que cumpla con los requisitos. Evaluando creación de pedido...');

                List<Tipo_de_tanque__c> tiposCandidatos = [
                    SELECT Id, Capacidad__c, Precio_de_lista__c
                    FROM Tipo_de_tanque__c
                    WHERE Capacidad__c = :capacidadDeseada
                      AND Precio_de_lista__c >= :precioMin
                      AND Precio_de_lista__c <= :precioMax
                    ORDER BY Precio_de_lista__c ASC
                    LIMIT 1
                ];

                if (!tiposCandidatos.isEmpty()) {
                    Tipo_de_tanque__c tipo = tiposCandidatos[0];

                    System.debug('📋 Tipo de tanque para pedido: ' + tipo.Id);
                    System.debug('🔍 Comparación: capacidad = ' + tipo.Capacidad__c + ' == ' + capacidadDeseada);
                    System.debug('🔍 Comparación: precio = ' + tipo.Precio_de_lista__c +
                                 ' dentro de rango [' + precioMin + ', ' + precioMax + ']');

                    Pedido_tanque__c pedido = new Pedido_tanque__c(
                        Tipo_de_tanque__c = tipo.Id,
                        Estado__c = 'Pendiente'
                    );
                    pedidosACrear.add(pedido);
                } else {
                    System.debug('⛔ No hay ningún tipo de tanque compatible para generar pedido.');
                }
            }
        }

        // Actualizar tanques reservados
        if (!tanquesAActualizar.isEmpty()) {
            update tanquesAActualizar;
            System.debug('🔄 Tanques actualizados a estado Reservado: ' + tanquesAActualizar.size());
        }

        // Insertar pedidos generados
        if (!pedidosACrear.isEmpty()) {
            insert pedidosACrear;
            System.debug('✅ Pedidos insertados: ' + pedidosACrear.size());
        } else {
            System.debug('ℹ️ No se generaron pedidos.');
        }

        System.debug('🏁 FIN del proceso de asignación de tanque.');
    }
}

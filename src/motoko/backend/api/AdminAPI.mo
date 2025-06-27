    // AdminAPI.mo - Admin Management Public API
    // Public interface layer for admin-related functions

    import Principal "mo:base/Principal";
    import Result "mo:base/Result";
    import Time "mo:base/Time";
    import Debug "mo:base/Debug";
    import Text "mo:base/Text";
    import Error "mo:base/Error";
    import Types "../types/APITypes";
    import AdminController "../controllers/AdminController";
    import SystemManager "../modules/SystemManager";
    import AuditLogger "../modules/AuditLogger";

    module AdminAPI {
        
        // Main gateway function for all admin requests
        public func handleAdminRequest(
            caller: Principal,
            request: Types.AdminRequest,
            controller: AdminController.AdminControllerState
        ) : async Types.AdminResponse {
            Debug.print("AdminAPI: Admin request received" # debug_show(request));
            try {
                let result = switch(request.action) {
                    // System Configuration
                    case (#CreateOrUpdateConfig(config)) {
                        AdminController.createOrUpdateConfig(controller, config.key, config.value, caller);
                    };

                    case (#UpdateUserLimits(limits)) {
                        #err("Not implemented");
                    };

                    case (#GetSystemConfig) {
                        #err("Not implemented");
                    };

                    case (#DeleteConfig(key)) {
                        AdminController.deleteConfig(controller, key.key, caller);
                    };


                    // Admin Management
                    case (#AdminManagement(action)) {
                        switch(action) {
                            case (#AddAdmin(params)) {
                                AdminController.addAdmin(controller, params.principal, caller);
                            };
                            case (#RemoveAdmin(params)) {
                                AdminController.removeAdmin(controller, params.principal, caller);
                            };
                        };
                    };

                    // System State Management
                    case (#MaintenanceMode(action)) {
                        switch(action) {
                            case (#Enable) {
                                AdminController.enableMaintenanceMode(controller, caller);
                            };
                            case (#Disable) {
                                AdminController.disableMaintenanceMode(controller, caller);
                            };
                        };
                    };

                    case (#EmergencyStop) {
                        AdminController.emergencyStop(controller, caller);
                    };

                };

                switch(result) {
                    case (#ok(data)) {
                        Debug.print("AdminAPI: Admin request completed successfully");
                        #Success({
                            data = data;
                            message = ?"Admin request completed successfully";
                        });
                    };
                    case (#err(error)) {
                        #Error({
                            code = "OPERATION_FAILED";
                            message = error;
                            details = null;
                        });
                    };
                    case (_) {
                        #Error({
                            code = "OPERATION_FAILED_UNKNOWN";
                            message = "Admin request failed, unknown error";
                            details = null;
                        });
                    };
                };
            } catch(error) {
                
                #Error({
                    code = "INTERNAL_ERROR";
                    message = "An unexpected error occurred";
                    details = ?debug_show(Error.message(error));
                });
            };
        };
    } 
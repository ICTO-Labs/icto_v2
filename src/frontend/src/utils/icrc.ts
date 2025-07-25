interface TransferResult {
    success: boolean;
    data?: any;
    error?: {
        type: string;
        message: string;
        details?: any;
    };
}

export function handleTransferResult(result: any): TransferResult {
    if (!result) {
        return {
            success: false,
            error: {
                type: 'UNKNOWN_ERROR',
                message: 'No result received from transfer'
            }
        };
    }

    // Handle successful transfer
    if ('Ok' in result) {
        return {
            success: true,
            data: result.Ok
        };
    }

    // Handle error cases
    if ('Err' in result) {
        const error = result.Err;
        
        // Handle different error types
        if (typeof error === 'object') {
            if ('InsufficientFunds' in error) {
                return {
                    success: false,
                    error: {
                        type: 'INSUFFICIENT_FUNDS',
                        message: `Insufficient funds. Available: ${error.InsufficientFunds.balance}`,
                        details: error.InsufficientFunds
                    }
                };
            }
            
            if ('BadFee' in error) {
                return {
                    success: false,
                    error: {
                        type: 'BAD_FEE',
                        message: `Invalid fee. Expected: ${error.BadFee.expected_fee}`,
                        details: error.BadFee
                    }
                };
            }
            
            if ('TooOld' in error) {
                return {
                    success: false,
                    error: {
                        type: 'TOO_OLD',
                        message: 'Transaction is too old',
                        details: error.TooOld
                    }
                };
            }
            
            if ('CreatedInFuture' in error) {
                return {
                    success: false,
                    error: {
                        type: 'CREATED_IN_FUTURE',
                        message: 'Transaction created in future',
                        details: error.CreatedInFuture
                    }
                };
            }
            
            if ('Duplicate' in error) {
                return {
                    success: false,
                    error: {
                        type: 'DUPLICATE',
                        message: `Duplicate transaction. Block: ${error.Duplicate.duplicate_of}`,
                        details: error.Duplicate
                    }
                };
            }
            
            if ('TemporarilyUnavailable' in error) {
                return {
                    success: false,
                    error: {
                        type: 'TEMPORARILY_UNAVAILABLE',
                        message: 'Service temporarily unavailable',
                        details: error.TemporarilyUnavailable
                    }
                };
            }
            
            if ('GenericError' in error) {
                return {
                    success: false,
                    error: {
                        type: 'GENERIC_ERROR',
                        message: error.GenericError.message || 'Generic error occurred',
                        details: error.GenericError
                    }
                };
            }
        }
        
        // Handle string errors
        if (typeof error === 'string') {
            return {
                success: false,
                error: {
                    type: 'STRING_ERROR',
                    message: error
                }
            };
        }
        
        // Fallback for unknown error format
        return {
            success: false,
            error: {
                type: 'UNKNOWN_ERROR',
                message: 'Unknown error occurred',
                details: error
            }
        };
    }

    // Fallback for unexpected result format
    return {
        success: false,
        error: {
            type: 'UNEXPECTED_FORMAT',
            message: 'Unexpected result format',
            details: result
        }
    };
}

export function formatTransferError(error: TransferResult['error']): string {
    if (!error) return 'Unknown error';
    
    switch (error.type) {
        case 'INSUFFICIENT_FUNDS':
            return 'Insufficient funds for this transaction';
        case 'BAD_FEE':
            return 'Invalid transaction fee';
        case 'TOO_OLD':
            return 'Transaction expired, please try again';
        case 'CREATED_IN_FUTURE':
            return 'Invalid transaction timestamp';
        case 'DUPLICATE':
            return 'Duplicate transaction detected';
        case 'TEMPORARILY_UNAVAILABLE':
            return 'Service temporarily unavailable, please try again';
        case 'GENERIC_ERROR':
        case 'STRING_ERROR':
        case 'UNKNOWN_ERROR':
        case 'UNEXPECTED_FORMAT':
        default:
            return error.message || 'Transaction failed';
    }
}

// Approve result interface
interface ApproveResult {
    success: boolean;
    data?: any;
    error?: {
        type: string;
        message: string;
        details?: any;
    };
}

// Handle ICRC2 approve results (note: keeping the original typo for compatibility)
export function hanldeApproveResult(result: any): ApproveResult {
    if (!result) {
        return {
            success: false,
            error: {
                type: 'UNKNOWN_ERROR',
                message: 'No result received from approve'
            }
        };
    }

    // Handle successful approve
    if ('Ok' in result) {
        return {
            success: true,
            data: result.Ok
        };
    }

    // Handle error cases
    if ('Err' in result) {
        const error = result.Err;
        
        // Handle different error types
        if (typeof error === 'object') {
            if ('InsufficientFunds' in error) {
                return {
                    success: false,
                    error: {
                        type: 'INSUFFICIENT_FUNDS',
                        message: `Insufficient funds. Available: ${error.InsufficientFunds.balance}`,
                        details: error.InsufficientFunds
                    }
                };
            }
            
            if ('BadFee' in error) {
                return {
                    success: false,
                    error: {
                        type: 'BAD_FEE',
                        message: `Invalid fee. Expected: ${error.BadFee.expected_fee}`,
                        details: error.BadFee
                    }
                };
            }
            
            if ('InsufficientAllowance' in error) {
                return {
                    success: false,
                    error: {
                        type: 'INSUFFICIENT_ALLOWANCE',
                        message: `Insufficient allowance. Current: ${error.InsufficientAllowance.allowance}`,
                        details: error.InsufficientAllowance
                    }
                };
            }
            
            if ('AllowanceChanged' in error) {
                return {
                    success: false,
                    error: {
                        type: 'ALLOWANCE_CHANGED',
                        message: `Allowance changed. Current: ${error.AllowanceChanged.current_allowance}`,
                        details: error.AllowanceChanged
                    }
                };
            }
            
            if ('Expired' in error) {
                return {
                    success: false,
                    error: {
                        type: 'EXPIRED',
                        message: 'Approval has expired',
                        details: error.Expired
                    }
                };
            }
            
            if ('TooOld' in error) {
                return {
                    success: false,
                    error: {
                        type: 'TOO_OLD',
                        message: 'Approval is too old',
                        details: error.TooOld
                    }
                };
            }
            
            if ('CreatedInFuture' in error) {
                return {
                    success: false,
                    error: {
                        type: 'CREATED_IN_FUTURE',
                        message: 'Approval created in future',
                        details: error.CreatedInFuture
                    }
                };
            }
            
            if ('Duplicate' in error) {
                return {
                    success: false,
                    error: {
                        type: 'DUPLICATE',
                        message: `Duplicate approval. Block: ${error.Duplicate.duplicate_of}`,
                        details: error.Duplicate
                    }
                };
            }
            
            if ('TemporarilyUnavailable' in error) {
                return {
                    success: false,
                    error: {
                        type: 'TEMPORARILY_UNAVAILABLE',
                        message: 'Service temporarily unavailable',
                        details: error.TemporarilyUnavailable
                    }
                };
            }
            
            if ('GenericError' in error) {
                return {
                    success: false,
                    error: {
                        type: 'GENERIC_ERROR',
                        message: error.GenericError.message || 'Generic error occurred',
                        details: error.GenericError
                    }
                };
            }
        }
        
        // Handle string errors
        if (typeof error === 'string') {
            return {
                success: false,
                error: {
                    type: 'STRING_ERROR',
                    message: error
                }
            };
        }
        
        // Fallback for unknown error format
        return {
            success: false,
            error: {
                type: 'UNKNOWN_ERROR',
                message: 'Unknown error occurred',
                details: error
            }
        };
    }

    // Fallback for unexpected result format
    return {
        success: false,
        error: {
            type: 'UNEXPECTED_FORMAT',
            message: 'Unexpected result format',
            details: result
        }
    };
}

// Corrected function name (without typo)
export function handleApproveResult(result: any): ApproveResult {
    return hanldeApproveResult(result);
}

// Format approve error messages
export function formatApproveError(error: ApproveResult['error']): string {
    if (!error) return 'Unknown error';
    
    switch (error.type) {
        case 'INSUFFICIENT_FUNDS':
            return 'Insufficient funds for approval';
        case 'BAD_FEE':
            return 'Invalid approval fee';
        case 'INSUFFICIENT_ALLOWANCE':
            return 'Insufficient allowance for this operation';
        case 'ALLOWANCE_CHANGED':
            return 'Allowance has changed, please try again';
        case 'EXPIRED':
            return 'Approval has expired';
        case 'TOO_OLD':
            return 'Approval expired, please try again';
        case 'CREATED_IN_FUTURE':
            return 'Invalid approval timestamp';
        case 'DUPLICATE':
            return 'Duplicate approval detected';
        case 'TEMPORARILY_UNAVAILABLE':
            return 'Service temporarily unavailable, please try again';
        case 'GENERIC_ERROR':
        case 'STRING_ERROR':
        case 'UNKNOWN_ERROR':
        case 'UNEXPECTED_FORMAT':
        default:
            return error.message || 'Approval failed';
    }
}

// Additional utility functions for ICRC operations

// Check if a result indicates success
export function isSuccessResult(result: any): boolean {
    return result && 'Ok' in result;
}

// Check if a result indicates an error
export function isErrorResult(result: any): boolean {
    return result && 'Err' in result;
}

// Extract the success data from a result
export function getSuccessData(result: any): any {
    if (isSuccessResult(result)) {
        return result.Ok;
    }
    return null;
}

// Extract the error data from a result
export function getErrorData(result: any): any {
    if (isErrorResult(result)) {
        return result.Err;
    }
    return null;
}

// Generic result handler for any ICRC operation
export function handleIcrcResult(result: any, operation: string = 'operation'): {
    success: boolean;
    data?: any;
    error?: string;
} {
    if (isSuccessResult(result)) {
        return {
            success: true,
            data: getSuccessData(result)
        };
    }
    
    if (isErrorResult(result)) {
        const error = getErrorData(result);
        let errorMessage = `${operation} failed`;
        
        if (typeof error === 'string') {
            errorMessage = error;
        } else if (typeof error === 'object' && error !== null) {
            // Try to extract a meaningful error message
            if (error.message) {
                errorMessage = error.message;
            } else if (error.GenericError?.message) {
                errorMessage = error.GenericError.message;
            } else {
                errorMessage = `${operation} failed: ${JSON.stringify(error)}`;
            }
        }
        
        return {
            success: false,
            error: errorMessage
        };
    }
    
    return {
        success: false,
        error: `${operation} failed: unexpected result format`
    };
}
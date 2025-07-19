import type { TransferResult, TransferError, ApproveError, ApproveResult } from "@dfinity/ledger-icp/dist/candid/ledger";
import type { TxIndex } from "@dfinity/ledger-icrc/dist/candid/icrc_ledger";

// Interface for formatted error information
export interface FormattedError {
    type: string;
    message: string;
    details?: Record<string, any>;
    severity: 'error' | 'warning';
    canRetry: boolean;
}

export const handleApproveError = (error: ApproveError): FormattedError => {
    if ('GenericError' in error) {
        return {
            type: 'GenericError',
            message: `System error: ${(error as any)?.GenericError?.message }`,
            details: {
                errorCode: (error as any)?.GenericError?.error_code?.toString(),
                originalMessage: (error as any)?.GenericError?.message
            },
            severity: 'error',
            canRetry: true
        };
    }

    if ('TemporarilyUnavailable' in error) {
        return {
            type: 'TemporarilyUnavailable',
            message: 'Service temporarily unavailable. Please try again later.',
            severity: 'warning',
            canRetry: true
        };
    }

    if ('BadBurn' in error) {
        return {
            type: 'BadBurn',
            message: `Invalid burn amount. Minimum required: ${(error as any)?.BadBurn?.min_burn_amount} tokens`,
            details: {
                minBurnAmount: (error as any)?.BadBurn?.min_burn_amount,
                minBurnAmountRaw: (error as any)?.BadBurn?.min_burn_amount?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if( 'InsufficientFunds' in error){
        return {
            type: 'InsufficientFunds',
            message: `Insufficient funds. Current balance: ${(error as any)?.InsufficientFunds?.balance} tokens`,
            details: {
                balance: (error as any)?.InsufficientFunds?.balance,
                balanceRaw: (error as any)?.InsufficientFunds?.balance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if( 'AllowanceChanged' in error){
        return {
            type: 'AllowanceChanged',
            message: `Allowance changed. New allowance: ${(error as any)?.AllowanceChanged?.current_allowance} tokens`,
            details: {
                allowance: (error as any)?.AllowanceChanged?.current_allowance,
                allowanceRaw: (error as any)?.AllowanceChanged?.current_allowance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }
    if('Expired' in error){
        return {
            type: 'Expired',
            message: `Expired. New allowance: ${(error as any)?.Expired?.allowance} tokens`,
            details: {
                allowance: (error as any)?.Expired?.allowance,
                allowanceRaw: (error as any)?.Expired?.allowance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }
    if('TooOld' in error){
        return {
            type: 'TooOld',
            message: `Too old. New allowance: ${(error as any)?.TooOld?.allowance} tokens`,
            details: {
                allowance: (error as any)?.TooOld?.allowance,
                allowanceRaw: (error as any)?.TooOld?.allowance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }
    if('CreatedInFuture' in error){
        return {
            type: 'CreatedInFuture',
            message: `Created in future. New allowance: ${(error as any)?.CreatedInFuture?.allowance} tokens`,
            details: {
                allowance: (error as any)?.CreatedInFuture?.allowance,
                allowanceRaw: (error as any)?.CreatedInFuture?.allowance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }
    if('Duplicate' in error){
        return {
            type: 'Duplicate',
            message: `Duplicate. New allowance: ${(error as any)?.Duplicate?.allowance} tokens`,
            details: {
                allowance: (error as any)?.Duplicate?.allowance,
                allowanceRaw: (error as any)?.Duplicate?.allowance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }
    if('TemporarilyUnavailable' in error){
        return {
            type: 'TemporarilyUnavailable',
            message: `Temporarily unavailable. New allowance: ${(error as any)?.TemporarilyUnavailable?.allowance} tokens`,
            details: {
                allowance: (error as any)?.TemporarilyUnavailable?.allowance,
                allowanceRaw: (error as any)?.TemporarilyUnavailable?.allowance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

     // Fallback case
     return {
        type: 'Unknown',
        message: 'Unknown error',
        severity: 'error',
        canRetry: false
    };
}

export const handleTransferError = (error: TransferError): FormattedError => {
    if ('GenericError' in error) {
        return {
            type: 'GenericError',
            message: `System error: ${(error as any)?.GenericError?.message }`,
            details: {
                errorCode: (error as any)?.GenericError?.error_code?.toString(),
                originalMessage: (error as any)?.GenericError?.message
            },
            severity: 'error',
            canRetry: true
        };
    }

    if ('TemporarilyUnavailable' in error) {
        return {
            type: 'TemporarilyUnavailable',
            message: 'Service temporarily unavailable. Please try again later.',
            severity: 'warning',
            canRetry: true
        };
    }

    if ('BadBurn' in error) {
        return {
            type: 'BadBurn',
            message: `Invalid burn amount. Minimum required: ${(error as any)?.BadBurn?.min_burn_amount} tokens`,
            details: {
                minBurnAmount: (error as any)?.BadBurn?.min_burn_amount,
                minBurnAmountRaw: (error as any)?.BadBurn?.min_burn_amount?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if ('Duplicate' in error) {
        return {
            type: 'Duplicate',
            message: `Duplicate transaction. Transaction already exists with ID: ${(error as any)?.Duplicate?.duplicate_of}`,
            details: {
                duplicateOf: (error as any)?.Duplicate?.duplicate_of?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if ('BadFee' in error) {
        return {
            type: 'BadFee',
            message: `Invalid transaction fee. Required fee: ${(error as any)?.BadFee?.expected_fee} tokens`,
            details: {
                expectedFee: (error as any)?.BadFee?.expected_fee,
                expectedFeeRaw: (error as any)?.BadFee?.expected_fee?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if ('CreatedInFuture' in error) {
        return {
            type: 'CreatedInFuture',
            message: `Invalid transaction time. Ledger time: ${(error as any)?.CreatedInFuture?.ledger_time}`,
            details: {
                ledgerTime: (error as any)?.CreatedInFuture?.ledger_time,
                ledgerTimeRaw: (error as any)?.CreatedInFuture?.ledger_time?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if ('TooOld' in error) {
        return {
            type: 'TooOld',
            message: 'Transaction too old and cannot be processed.',
            severity: 'error',
            canRetry: false
        };
    }

    if ('InsufficientFunds' in error) {
        return {
            type: 'InsufficientFunds',
            message: `Insufficient funds. Current balance: ${(error as any)?.InsufficientFunds?.balance} tokens`,
            details: {
                balance: (error as any)?.InsufficientFunds?.balance,
                balanceRaw: (error as any)?.InsufficientFunds?.balance?.toString()
            },
            severity: 'error',
            canRetry: false
        };
    }

    if('code' in error) {
        switch (error.code) {
            case 3000:
            case 3001:
                return {
                    type: 'UserCanceled',
                    message: 'User canceled the transaction',
                    severity: 'warning',
                    canRetry: false
                };
            default:
                return {
                    type: 'Unknown',
                    message: 'Unknown error, code: ' + error.code,
                    severity: 'error',
                    canRetry: false
                };
        }
    }

    if('name' in error) {
        switch (error.name) {
            case 'AgentError':
                return {
                    type: 'AgentError',
                    message: 'Agent error',
                    severity: 'warning',
                    canRetry: false
                };
            default:
                return {
                    type: 'Unknown',
                    message: 'Unknown error, name: ' + error.name,
                    severity: 'error',
                    canRetry: false
                };
        }
    }

    // Fallback case
    return {
        type: 'Unknown',
        message: 'Unknown error',
        severity: 'error',
        canRetry: false
    };
};

// Utility function to handle TransferResult
export const hanldeApproveResult = (result: ApproveResult): { success: boolean; data?: TxIndex; error?: FormattedError } => {
    if ('Ok' in result) {
        return {
            success: true,
            data: result.Ok
        };
    }

    if ('Err' in result) {
        return {
            success: false,
            error: handleApproveError(result.Err)
        };
    }

    // Fallback
    return {
        success: false,
        error: {
            type: 'Unknown',
            message: 'Unknown error',
            severity: 'error',
            canRetry: false
        }
    };
};
export const handleTransferResult = (result: TransferResult): { success: boolean; data?: TxIndex; error?: FormattedError } => {
    if ('Ok' in result) {
        return {
            success: true,
            data: result.Ok
        };
    }

    if ('Err' in result) {
        return {
            success: false,
            error: handleTransferError(result.Err)
        };
    }

    // Fallback
    return {
        success: false,
        error: {
            type: 'Unknown',
            message: 'Unknown error',
            severity: 'error',
            canRetry: false
        }
    };
};

// Helper function to get short error message
export const getShortErrorMessage = (error: TransferError): string => {
    const formatted = handleTransferError(error);
    return formatted.message;
};
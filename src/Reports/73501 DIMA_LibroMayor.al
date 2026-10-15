// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Utilities;
using Microsoft.Foundation.Company;

/// <summary>
/// Generates detailed trial balance with individual transaction breakdowns for each G/L account.
/// Provides comprehensive audit trail with transaction-level detail including closing entries and corrections analysis.
/// </summary>
/// <remarks>
/// Data sources: G/L Account and G/L Entry tables with posting account filtering and transaction detail display.
/// Supports multiple filter options: balance-only accounts, closing entries, reversed entries, and correction entries.
/// Used for detailed financial analysis, audit procedures, and transaction-level reconciliation requirements.
/// </remarks>
report 73501 "DIMA Libro Mayor"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/ReportsLayout/DIMA_LibroMayor.rdlc';
    AdditionalSearchTerms = 'payment due,order status';
    ApplicationArea = Basic, Suite;
    Caption = 'DIMA Libro Mayor';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = where("Account Type" = const(Posting));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Income/Balance", "Debit/Credit", "Date Filter";
            column(PeriodGLDtFilter; StrSubstNo(Text000, GLDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(COMPANYLOGO; CompanyInfo.Picture)
            {
            }
            column(ExcludeBalanceOnly; ExcludeBalanceOnly)
            {
            }
            column(PrintReversedEntries; PrintReversedEntries)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(PrintClosingEntries; PrintClosingEntries)
            {
            }
            column(PrintOnlyCorrections; PrintOnlyCorrections)
            {
            }
            column(GLAccTableCaption; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(No_GLAcc; "No.")
            {
            }
            column(DetailTrialBalCaption; DetailTrialBalCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(OnlyCorrectionsCaption; OnlyCorrectionsCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(GLEntryDebitAmtCaption; GLEntryDebitAmtCaptionLbl)
            {
            }
            column(GLEntryCreditAmtCaption; GLEntryCreditAmtCaptionLbl)
            {
            }
            column(GLBalCaption; GLBalCaptionLbl)
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Name_GLAcc; "G/L Account".Name)
                {
                }
                column(StartBalance; StartBalance)
                {
                    AutoFormatType = 1;
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter"), "Dimension Set ID" = field("Dimension Set ID Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = sorting("G/L Account No.", "Posting Date");
                    column(VATAmount_GLEntry; "VAT Amount")
                    {
                        IncludeCaption = true;
                    }
                    column(DebitAmount_GLEntry; "Debit Amount")
                    {
                    }
                    column(CreditAmount_GLEntry; "Credit Amount")
                    {
                    }
                    column(PostingDate_GLEntry; Format("Posting Date"))
                    {
                    }
                    column(DocumentNo_GLEntry; "Document No.")
                    {
                    }
                    column(ExtDocNo_GLEntry; "External Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description_GLEntry; Description)
                    {
                    }
                    column(GLBalance; GLBalance)
                    {
                        AutoFormatType = 1;
                    }
                    column(EntryNo_GLEntry; "Entry No.")
                    {
                    }
                    column(ClosingEntry; ClosingEntry)
                    {
                    }
                    column(Reversed_GLEntry; Reversed)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if PrintOnlyCorrections then
                            if not (("Debit Amount" < 0) or ("Credit Amount" < 0)) then
                                CurrReport.Skip();
                        if not PrintReversedEntries and Reversed then
                            CurrReport.Skip();

                        ClosingEntry := "Posting Date" = ClosingDate("Posting Date");

                        if ClosingEntry and not PrintClosingEntries then
                            CurrReport.Skip();

                        GLBalance := GLBalance + Amount;

                        NumberOfGLEntryLines += 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        GLBalance := StartBalance;

                        OnAfterOnPreDataItemGLEntry("G/L Entry");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CurrReport.PrintOnlyIfDetail := ExcludeBalanceOnly or (StartBalance = 0);
                end;
            }

            trigger OnAfterGetRecord()
            var
                GLEntry: Record "G/L Entry";
                Date: Record Date;
            begin
                StartBalance := 0;
                if GLDateFilter <> '' then begin
                    Date.SetRange("Period Type", Date."Period Type"::Date);
                    Date.SetFilter("Period Start", GLDateFilter);
                    if Date.FindFirst() then begin
                        SetRange("Date Filter", 0D, ClosingDate(Date."Period Start" - 1));
                        CalcFields("Net Change");
                        StartBalance := "Net Change";
                        SetFilter("Date Filter", GLDateFilter);
                    end;
                end;

                if PrintOnlyOnePerPage then begin
                    GLEntry.Reset();
                    GLEntry.SetRange("G/L Account No.", "No.");
                    if CurrReport.PrintOnlyIfDetail and (not GLEntry.IsEmpty()) then
                        PageGroupNo := PageGroupNo + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Detail Trial Balance';
        AboutText = 'View bank account balances at the end of the period, including the opening balance, each transaction within the period, and the closing balance grouped by bank. View a running balance and reconciled entries.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPageperGLAcc; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Una página nueva para cada cuenta';
                        ToolTip = 'Especifica si la información de cada cuenta de contabilidad general se imprime en una nueva página en caso que haya elegido incluir dos o más cuentas contables en el informe.';
                    }
                    field(ExcludeGLAccsHaveBalanceOnly; ExcludeBalanceOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Excluir solo cuentas con saldo a fecha';
                        MultiLine = true;
                        ToolTip = 'Especifica si no desea incluir en el informe los movimientos de las cuentas de contabilidad que tengan saldo, aunque no tengan un saldo de período durante el período seleccionado.';
                    }
                    field(InclClosingEntriesWithinPeriod; PrintClosingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Incluir movs. regul. para el periodo';
                        MultiLine = true;
                        ToolTip = 'Especifica si desea que el informe incluya movimientos de cierre. Resulta útil si el informe abarca un ejercicio completo. Los movimientos de cierre se relacionan con una fecha ficticia comprendida entre el último día de un ejercicio y el primer día del siguiente. Dichos movimientos tienen una C antes de la fecha, por ejemplo C123194. Si no selecciona este campo, no se muestra ningún movimiento de cierre.';
                    }
                    field(IncludeReversedEntries; PrintReversedEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Incluir movs. revertidos';
                        ToolTip = 'Especifica si desea incluir movimientos revertidos en el informe.';
                    }
                    field(PrintCorrectionsOnly; PrintOnlyCorrections)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Imprimir solo correcciones';
                        ToolTip = 'Especifica si desea que el informe muestre únicamente los movimientos revertidos y los movimientos que los corrigen.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        PostingDateCaption = 'Fecha registro';
        DocNoCaption = 'Nº documento';
        DescCaption = 'Descripción';
        VATAmtCaption = 'Importe IVA';
        EntryNoCaption = 'Entry No.';
    }

    trigger OnPreReport()
    begin
        StartDateTime := CurrentDateTime();
        "G/L Account".SecurityFiltering(SecurityFilter::Filtered);
        "G/L Entry".SecurityFiltering(SecurityFilter::Filtered);
        GLFilter := "G/L Account".GetFilters();
        GLDateFilter := "G/L Account".GetFilter("Date Filter");
        CompanyInfo.Get();
        CompanyInfo.CalcFields(Picture);

        OnAfterOnPreReport("G/L Account", ExcludeBalanceOnly);
    end;

    trigger OnPostReport()
    begin
        FinishDateTime := CurrentDateTime();
        LogReportTelemetry(StartDateTime, FinishDateTime, NumberOfGLEntryLines);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Periodo: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLDateFilter: Text;
        GLBalance: Decimal;
        StartBalance: Decimal;
        PrintOnlyOnePerPage: Boolean;
        ExcludeBalanceOnly: Boolean;
        PrintClosingEntries: Boolean;
        PrintOnlyCorrections: Boolean;
        PrintReversedEntries: Boolean;
        PageGroupNo: Integer;
        ClosingEntry: Boolean;
        DetailTrialBalCaptionLbl: Label 'Libro Mayor';
        PageCaptionLbl: Label 'Pág';
        BalanceCaptionLbl: Label 'Esto también incluye las cuentas que solo tienen un saldo.';
        PeriodCaptionLbl: Label 'Este informe también incluye movimientos de regularización dentro del periodo.';
        OnlyCorrectionsCaptionLbl: Label 'Only corrections are included.';
        NetChangeCaptionLbl: Label 'Saldo Periodo';
        GLEntryDebitAmtCaptionLbl: Label 'Debe';
        GLEntryCreditAmtCaptionLbl: Label 'Haber';
        GLBalCaptionLbl: Label 'Saldo';
        TelemetryCategoryTxt: Label 'Report', Locked = true;
        DetailedTrialBalanceReportGeneratedTxt: Label 'Detail Trial Balance report generated.', Locked = true;
        CompanyInfo: Record "Company Information";

    protected var
        GLFilter: Text;
        NumberOfGLEntryLines: Integer;
        StartDateTime: DateTime;
        FinishDateTime: DateTime;

    /// <summary>
    /// Initializes report parameters for programmatic execution with detailed filtering and display options.
    /// Configures entry type filters, page break options, and transaction inclusion criteria for customized trial balance generation.
    /// </summary>
    /// <param name="NewPrintOnlyOnePerPage">Whether to print only one account per page</param>
    /// <param name="NewExcludeBalanceOnly">Whether to exclude accounts with balance-only information</param>
    /// <param name="NewPrintClosingEntries">Whether to include closing entries in the report</param>
    /// <param name="NewPrintReversedEntries">Whether to include reversed entries in the report</param>
    /// <param name="NewPrintOnlyCorrections">Whether to print only correction entries</param>
    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewExcludeBalanceOnly: Boolean; NewPrintClosingEntries: Boolean; NewPrintReversedEntries: Boolean; NewPrintOnlyCorrections: Boolean)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        ExcludeBalanceOnly := NewExcludeBalanceOnly;
        PrintClosingEntries := NewPrintClosingEntries;
        PrintReversedEntries := NewPrintReversedEntries;
        PrintOnlyCorrections := NewPrintOnlyCorrections;
    end;

    local procedure LogReportTelemetry(StartDateTime: DateTime; FinishDateTime: DateTime; NumberOfLines: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
        ReportDuration: BigInteger;
    begin
        ReportDuration := FinishDateTime - StartDateTime;
        Dimensions.Add('Category', TelemetryCategoryTxt);
        Dimensions.Add('ReportStartTime', Format(StartDateTime, 0, 9));
        Dimensions.Add('ReportFinishTime', Format(FinishDateTime, 0, 9));
        Dimensions.Add('ReportDuration', Format(ReportDuration));
        Dimensions.Add('NumberOfLines', Format(NumberOfLines));
        Session.LogMessage('0000FJL', DetailedTrialBalanceReportGeneratedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    [IntegrationEvent(false, false)]
    /// <summary>
    /// Integration event raised after G/L Entry data item preprocessing for customization of entry filtering or data modification.
    /// Allows extensions to modify G/L Entry record properties or apply additional filters before report generation.
    /// </summary>
    /// <param name="GLEntry">G/L Entry record reference for modification by subscribers</param>
    local procedure OnAfterOnPreDataItemGLEntry(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    /// <summary>
    /// Integration event raised after report preprocessing for customization of G/L Account filtering or exclusion criteria.
    /// Allows extensions to modify account selection logic and balance exclusion rules before detail processing.
    /// </summary>
    /// <param name="GLAccount">G/L Account record reference for modification by subscribers</param>
    /// <param name="ExcludeBalanceOnly">Balance exclusion flag that can be modified by subscribers</param>
    local procedure OnAfterOnPreReport(var GLAccount: Record "G/L Account"; var ExcludeBalanceOnly: Boolean)
    begin
    end;
}


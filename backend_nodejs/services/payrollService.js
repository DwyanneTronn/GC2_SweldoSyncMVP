// Payroll calculation service - extracted from server.js
const INDUSTRY_CONFIG = {
  standard: {
    label1: "Days Worked",
    label2: "Overtime (Hrs)",
    label3: "Holiday OT (Hrs)",
    calculate: (basic, val1, val2, val3) => {
      const dailyRate = (basic * 12) / 261;
      const basicPay = dailyRate * val1;
      const otPay = (dailyRate / 8) * 1.25 * val2;
      const holidayOtPay = (dailyRate / 8) * 2.0 * val3;
      return { basicPay, variablePay: otPay + holidayOtPay, variableLabel: "Overtime/Holiday Pay" };
    }
  },
  bpo: {
    label1: "Days Worked",
    label2: "Night Diff (Hrs)",
    label3: "Holiday OT (Hrs)",
    calculate: (basic, val1, val2, val3) => {
      const dailyRate = (basic * 12) / 261;
      const basicPay = dailyRate * val1;
      const ndPay = (dailyRate / 8) * 0.10 * val2;
      const holidayOtPay = (dailyRate / 8) * 2.0 * val3;
      return { basicPay, variablePay: ndPay + holidayOtPay, variableLabel: "Differentials/Holiday Pay" };
    }
  },
  airline: {
    label1: "Base Pay %",
    label2: "Flight Hours",
    label3: "Holiday Flight (Hrs)",
    calculate: (basic, val1, val2, val3) => {
      const basicPay = basic * (val1 > 0 ? 1 : 0);
      const flightRate = 1500;
      const flightPay = val2 * flightRate;
      const holidayFlightPay = val3 * (flightRate * 2.0);
      return { basicPay, variablePay: flightPay + holidayFlightPay, variableLabel: "Flight Pay" };
    }
  }
};

const calculatePayroll = async (industry, employees, companyId) => {
  const config = INDUSTRY_CONFIG[industry];
  if (!config) {
    throw new Error('Invalid industry specified');
  }

  const calculatedPayslips = employees.map(emp => {
    const { basicPay, variablePay, variableLabel } = config.calculate(
      emp.basicSalary || emp.basic,
      emp.inputs.val1 || 0,
      emp.inputs.val2 || 0,
      emp.inputs.val3 || 0
    );

    const gross = basicPay + variablePay;
    const deductions = gross * 0.12; // Simplified for MVP
    const netPay = gross - deductions;

    return {
      employeeId: emp._id || emp.id,
      employeeName: emp.name,
      basicEarned: basicPay,
      variablePay: variablePay,
      variableLabel: variableLabel,
      deductions: deductions,
      netPay: netPay,
      inputs: emp.inputs
    };
  });

  const totalCost = calculatedPayslips.reduce((sum, p) => sum + p.netPay, 0);

  return {
    payslips: calculatedPayslips,
    totalCost
  };
};

module.exports = {
  calculatePayroll,
  INDUSTRY_CONFIG
};


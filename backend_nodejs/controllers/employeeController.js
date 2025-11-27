const Employee = require('../models/Employee');

// Get all employees for a company
exports.getEmployees = async (req, res) => {
  try {
    const employees = await Employee.find({ 
      company: req.company._id,
      isActive: true 
    }).sort({ name: 1 });

    res.json({ employees });
  } catch (error) {
    console.error('Get employees error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Create employee
exports.createEmployee = async (req, res) => {
  try {
    const { employeeId, name, role, basicSalary } = req.body;

    if (!employeeId || !name || !role || !basicSalary) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const employee = new Employee({
      company: req.company._id,
      employeeId,
      name,
      role,
      basicSalary
    });

    await employee.save();
    res.status(201).json({ employee });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ error: 'Employee ID already exists' });
    }
    console.error('Create employee error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update employee
exports.updateEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, role, basicSalary } = req.body;

    const employee = await Employee.findOneAndUpdate(
      { _id: id, company: req.company._id },
      { name, role, basicSalary, updatedAt: Date.now() },
      { new: true }
    );

    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    res.json({ employee });
  } catch (error) {
    console.error('Update employee error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete employee (soft delete)
exports.deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params;

    const employee = await Employee.findOneAndUpdate(
      { _id: id, company: req.company._id },
      { isActive: false },
      { new: true }
    );

    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    res.json({ message: 'Employee deleted successfully' });
  } catch (error) {
    console.error('Delete employee error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};


#include "itemmodel.h"
#include <QRandomGenerator>
#include <QDate>

ItemModel::ItemModel(QObject *parent)
    : QAbstractListModel(parent)
{
    loadSampleData();
}

int ItemModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_items.count();
}

QVariant ItemModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.count())
        return QVariant();

    const TableItem &item = m_items.at(index.row());

    switch (role) {
    case NameRole: return item.name;
    case RoleRole: return item.role;
    case DepartmentRole: return item.department;
    case SalaryRole: return item.salary;
    case IsActiveRole: return item.isActive;
    case HireDateRole: return item.hireDate;
    case StatusRole: return item.status;
    case RemoteWorkRole: return item.remoteWork;
    case ContractTypeRole: return item.contractType;
    default: return QVariant();
    }
}

QHash<int, QByteArray> ItemModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[RoleRole] = "role";
    roles[DepartmentRole] = "department";
    roles[SalaryRole] = "salary";
    roles[IsActiveRole] = "isActive";
    roles[HireDateRole] = "hireDate";
    roles[StatusRole] = "status";
    roles[RemoteWorkRole] = "remoteWork";
    roles[ContractTypeRole] = "contractType";
    return roles;
}

void ItemModel::addItem(const QString &name,
                        const QString &role,
                        const QString &department,
                        double salary,
                        bool isActive,
                        const QDate &hireDate,
                        const QString &status,
                        bool remoteWork,
                        const QString &contractType)
{
    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append({name, role, department, salary, isActive, hireDate, status, remoteWork, contractType});
    endInsertRows();
    emit activeCountChanged();
}

void ItemModel::removeItem(int index)
{
    if (index < 0 || index >= m_items.count())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    endRemoveRows();
    emit activeCountChanged();
}

void ItemModel::updateItem(int index, const QString &name, const QString &role, const QString &department)
{
    if (index < 0 || index >= m_items.count())
        return;

    m_items[index].name = name;
    m_items[index].role = role;
    m_items[index].department = department;

    QModelIndex modelIndex = createIndex(index, 0);
    emit dataChanged(modelIndex, modelIndex, {NameRole, RoleRole, DepartmentRole});
}

int ItemModel::activeCount() const
{
    int count = 0;
    for (const auto &item : m_items)
        if (item.isActive)
            count++;
    return count;
}

void ItemModel::loadSampleData()
{
    beginResetModel();
    m_items.clear();

    QStringList names = {
        "Alice Johnson", "Bob Smith", "Charlie Brown", "Diana Davis", "Eve Wilson",
        "Frank Miller", "Grace Lee", "Henry Taylor", "Ivy Chen", "Jack Anderson"
    };

    QStringList roles = {
        "Developer", "Designer", "Manager", "QA", "DevOps",
        "Data Scientist", "Product Owner", "Admin", "Analyst", "Tech Lead"
    };

    QStringList departments = {
        "Engineering", "Design", "Management", "QA", "Operations",
        "Data", "Product", "IT", "Business", "Engineering"
    };

    QStringList statuses = {"active", "pending", "inactive"};
    QStringList contractTypes = {"Full-time", "Part-time", "Freelancer", "Intern"};

    for (int i = 0; i < 10; ++i) {
        double salary = 40000.0 + QRandomGenerator::global()->generateDouble() * (120000.0 - 40000.0);

        m_items.append({
            names[i],
            roles[i],
            departments[i],
            salary,
            i % 3 != 0,
            QDate::currentDate().addDays(-QRandomGenerator::global()->bounded(2000)),
            statuses.at(QRandomGenerator::global()->bounded(statuses.size())),
            QRandomGenerator::global()->bounded(2) == 1,
            contractTypes.at(QRandomGenerator::global()->bounded(contractTypes.size()))
        });
    }


    endResetModel();
    emit activeCountChanged();
}

void ItemModel::moveItem(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_items.count() ||
        toIndex < 0 || toIndex >= m_items.count() ||
        fromIndex == toIndex)
        return;

    int destination = toIndex;
    if (toIndex > fromIndex)
        destination = toIndex + 1;

    beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), destination);
    m_items.move(fromIndex, toIndex);
    endMoveRows();
}


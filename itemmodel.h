// itemmodel.h
#ifndef ITEMMODEL_H
#define ITEMMODEL_H

#include <QAbstractListModel>
#include <QDate>

struct TableItem {
    QString name;
    QString role;
    QString department;
    double salary;
    bool isActive;
    QDate hireDate;
    QString status;       // "active", "pending", "inactive"
    bool remoteWork;      // checkbox type
    QString contractType; // combobox
};

class ItemModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int activeCount READ activeCount NOTIFY activeCountChanged)

public:
    explicit ItemModel(QObject *parent = nullptr);

    enum Roles {
        NameRole = Qt::UserRole + 1,
        RoleRole,
        DepartmentRole,
        SalaryRole,
        IsActiveRole,
        HireDateRole,
        StatusRole,
        RemoteWorkRole,
        ContractTypeRole
    };
    Q_ENUM(Roles)

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addItem(
        const QString &name,
        const QString &role,
        const QString &department,
        double salary,
        bool isActive,
        const QDate &hireDate,
        const QString &status,
        bool remoteWork,
        const QString &contractType
        );

    Q_INVOKABLE void loadSampleData();
    Q_INVOKABLE void removeItem(int index);
    Q_INVOKABLE void moveItem(int fromIndex, int toIndex);
    Q_INVOKABLE void updateItem(int index,
                                const QString &name,
                                const QString &role,
                                const QString &department);

    int activeCount() const;

signals:
    void activeCountChanged();

private:
    QList<TableItem> m_items;
};

#endif // ITEMMODEL_H

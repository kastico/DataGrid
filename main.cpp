#include "itemmodel.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("YourCompany");
    app.setOrganizationDomain("yourcompany.com");
    app.setApplicationName("DataGridApp");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    qmlRegisterType<ItemModel>("CustomModels", 1, 0, "ItemModel");
    engine.loadFromModule("DataGrid", "Main");

    return app.exec();
}

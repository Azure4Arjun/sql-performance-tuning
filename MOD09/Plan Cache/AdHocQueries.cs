using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;

namespace ExecAdHoc
{
    class ExecAdHoc
    {
        static void Main(string[] args)
        {
            string connString = @"Server=(local);DataBase=AdventureWorks2008R2;Integrated Security=SSPI";
            SqlConnection conn = new SqlConnection(connString);
                conn.Open();
                for (int i = 20000; i < 25000; i = i + 1)
                {
                    string query = "SELECT h.[SalesOrderID], COUNT(h.[SalesOrderID]), SUM([TotalDue]) FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderId WHERE h.[CustomerID] = "+ i + " GROUP BY h.[SalesOrderID]";
                    SqlCommand command = new SqlCommand(query, conn);
                    command.ExecuteNonQuery();
                }
                conn.Close();
            }
        }
    }


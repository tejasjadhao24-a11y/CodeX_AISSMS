import sqlite3
import os

def ensure_columns(db_path):
    if not os.path.exists(db_path):
        print(f"Database {db_path} does not exist yet. It will be created by db.create_all().")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # 1. Check 'rides' table for 'started_at'
    cursor.execute("PRAGMA table_info(rides)")
    rides_columns = [row[1] for row in cursor.fetchall()]
    print(f"Existing columns in rides ({db_path}): {rides_columns}")

    if 'started_at' not in rides_columns and len(rides_columns) > 0:
        print("Adding column 'started_at' to 'rides' table...")
        cursor.execute("ALTER TABLE rides ADD COLUMN started_at DATETIME;")
        conn.commit()
        print("Column 'started_at' added successfully.")
    else:
        print("Column 'started_at' already exists or table not created yet.")

    if 'gender_preference' not in rides_columns and len(rides_columns) > 0:
        print("Adding column 'gender_preference' to 'rides' table...")
        cursor.execute("ALTER TABLE rides ADD COLUMN gender_preference VARCHAR(20) DEFAULT 'All';")
        conn.commit()
        print("Column 'gender_preference' added successfully.")
    else:
        print("Column 'gender_preference' already exists or table not created yet.")

    # 2. Check 'users' table for 'is_admin'
    cursor.execute("PRAGMA table_info(users)")
    users_columns = [row[1] for row in cursor.fetchall()]
    if 'is_admin' not in users_columns and len(users_columns) > 0:
        print("Adding column 'is_admin' to 'users' table...")
        cursor.execute("ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT 0;")
        conn.commit()
        print("Column 'is_admin' added successfully.")
    else:
        print("Column 'is_admin' already exists or table not created yet.")

    # 3. Check 'bike_rentals' table for 'payment_method'
    cursor.execute("PRAGMA table_info(bike_rentals)")
    rentals_columns = [row[1] for row in cursor.fetchall()]
    if 'payment_method' not in rentals_columns and len(rentals_columns) > 0:
        print("Adding column 'payment_method' to 'bike_rentals' table...")
        cursor.execute("ALTER TABLE bike_rentals ADD COLUMN payment_method VARCHAR(20) DEFAULT 'UPI';")
        conn.commit()
        print("Column 'payment_method' added to bike_rentals.")
    else:
        print("Column 'payment_method' in bike_rentals already exists or table not created yet.")

    # 4. Check 'bikes' table for 'payment_method'
    cursor.execute("PRAGMA table_info(bikes)")
    bikes_columns = [row[1] for row in cursor.fetchall()]
    if 'payment_method' not in bikes_columns and len(bikes_columns) > 0:
        print("Adding column 'payment_method' to 'bikes' table...")
        cursor.execute("ALTER TABLE bikes ADD COLUMN payment_method VARCHAR(20) DEFAULT 'Both';")
        conn.commit()
        print("Column 'payment_method' added to bikes.")
    else:
        print("Column 'payment_method' in bikes already exists or table not created yet.")

    # 5. Check 'users' table for location, avatar, and document uploads
    extra_user_cols = {
        'current_lat': 'FLOAT',
        'current_lng': 'FLOAT',
        'avatar_url': 'VARCHAR(255)',
        'license_photo': 'VARCHAR(255)',
        'rc_photo': 'VARCHAR(255)',
    }
    for col_name, col_type in extra_user_cols.items():
        if col_name not in users_columns and len(users_columns) > 0:
            print(f"Adding column '{col_name}' to 'users' table...")
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_type};")
            conn.commit()
            print(f"Column '{col_name}' added to users.")

    conn.close()

if __name__ == '__main__':
    backend_db = os.path.join(os.path.dirname(__file__), 'instance', 'campus_lift.db')
    ensure_columns(backend_db)
